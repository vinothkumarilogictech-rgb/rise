import io
import os
import tempfile
import logging
import subprocess
from typing import Optional
import pypdf

logger = logging.getLogger(__name__)

MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB limit

def extract_text_from_pdf(file_bytes: bytes) -> str:
    """
    Extracts text from all pages of a PDF document using pypdf.
    """
    try:
        reader = pypdf.PdfReader(io.BytesIO(file_bytes))
        pages_text = []
        for idx, page in enumerate(reader.pages):
            text = page.extract_text()
            if text and text.strip():
                pages_text.append(f"--- Page {idx + 1} ---\n{text.strip()}")
        
        full_text = "\n\n".join(pages_text)
        if not full_text.strip():
            logger.warning("PDF has no extractable text. It may contain scanned images.")
        return full_text
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {e}")
        raise ValueError(f"Failed to read PDF file: {str(e)}")

def extract_text_from_image_ocr(file_bytes: bytes, extension: str = ".png") -> str:
    """
    Extracts text from image files (PNG, JPG, JPEG) using Windows native OCR engine.
    """
    with tempfile.NamedTemporaryFile(suffix=extension, delete=False) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        ps_script = f"""
$OutputEncoding = [System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {{ $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' }}[0]
function Await($WinRtTask, $ResultType) {{
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}}
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime] | Out-Null

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync('{tmp_path}')) ([Windows.Storage.StorageFile])
$stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
$decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
$bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if (-not $engine) {{
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('en-US'))
}}
$ocrResult = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
$lines = $ocrResult.Lines | ForEach-Object {{ $_.Text }}
$lines -join "`n"
"""
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=45
        )

        if result.returncode == 0:
            extracted = result.stdout.strip()
            if extracted:
                return extracted
            logger.warning("OCR returned empty text from image.")
            return ""
        else:
            logger.warning(f"PowerShell OCR non-zero returncode {result.returncode}: {result.stderr}")
            return ""
    except Exception as e:
        logger.error(f"Error during Windows OCR extraction: {e}")
        return ""
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass

def extract_text_from_file(filename: str, file_bytes: bytes) -> str:
    """
    Dispatcher to extract text from PDF or images based on file extension.
    """
    if len(file_bytes) > MAX_FILE_SIZE_BYTES:
        raise ValueError(f"File size exceeds maximum allowed limit of {MAX_FILE_SIZE_BYTES // (1024*1024)}MB.")

    lower = filename.lower()
    if lower.endswith(".pdf"):
        return extract_text_from_pdf(file_bytes)
    elif lower.endswith((".png", ".jpg", ".jpeg")):
        ext = os.path.splitext(lower)[1]
        return extract_text_from_image_ocr(file_bytes, extension=ext)
    else:
        raise ValueError("Unsupported file type. Please upload a PDF, PNG, JPG, or JPEG file.")
