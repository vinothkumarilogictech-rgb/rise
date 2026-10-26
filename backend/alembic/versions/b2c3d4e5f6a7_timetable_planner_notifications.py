"""timetable_planner_notifications

Revision ID: b2c3d4e5f6a7
Revises: 7a8b9c0d1e2f
Create Date: 2026-10-26 10:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector

# revision identifiers, used by Alembic.
revision: str = 'b2c3d4e5f6a7'
down_revision: Union[str, Sequence[str], None] = '7a8b9c0d1e2f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = Inspector.from_engine(bind)
    existing_tables = inspector.get_table_names()

    # 1. Update tasks table columns if not present
    existing_task_cols = [c['name'] for c in inspector.get_columns('tasks')]
    with op.batch_alter_table('tasks', schema=None) as batch_op:
        if 'start_time' not in existing_task_cols:
            batch_op.add_column(sa.Column('start_time', sa.String(length=20), nullable=True))
        if 'end_time' not in existing_task_cols:
            batch_op.add_column(sa.Column('end_time', sa.String(length=20), nullable=True))
        if 'weekday' not in existing_task_cols:
            batch_op.add_column(sa.Column('weekday', sa.String(length=20), nullable=True))
        if 'session_type' not in existing_task_cols:
            batch_op.add_column(sa.Column('session_type', sa.String(length=50), nullable=True, server_default='study'))
        if 'import_batch_id' not in existing_task_cols:
            batch_op.add_column(sa.Column('import_batch_id', sa.String(length=36), nullable=True))
            batch_op.create_index(batch_op.f('ix_tasks_import_batch_id'), ['import_batch_id'], unique=False)

    # 2. Update user_preferences table columns if not present
    existing_pref_cols = [c['name'] for c in inspector.get_columns('user_preferences')]
    with op.batch_alter_table('user_preferences', schema=None) as batch_op:
        if 'reminder_lead_time_minutes' not in existing_pref_cols:
            batch_op.add_column(sa.Column('reminder_lead_time_minutes', sa.Integer(), nullable=True, server_default='15'))
        if 'preferred_planning_time' not in existing_pref_cols:
            batch_op.add_column(sa.Column('preferred_planning_time', sa.String(length=10), nullable=True, server_default='07:00'))
        if 'quiet_hours_start' not in existing_pref_cols:
            batch_op.add_column(sa.Column('quiet_hours_start', sa.String(length=10), nullable=True, server_default='22:00'))
        if 'quiet_hours_end' not in existing_pref_cols:
            batch_op.add_column(sa.Column('quiet_hours_end', sa.String(length=10), nullable=True, server_default='06:00'))
        if 'timezone' not in existing_pref_cols:
            batch_op.add_column(sa.Column('timezone', sa.String(length=50), nullable=True, server_default='Asia/Kolkata'))
        if 'notify_study_reminders' not in existing_pref_cols:
            batch_op.add_column(sa.Column('notify_study_reminders', sa.Boolean(), nullable=True, server_default='1'))
        if 'notify_daily_plan' not in existing_pref_cols:
            batch_op.add_column(sa.Column('notify_daily_plan', sa.Boolean(), nullable=True, server_default='1'))
        if 'notify_overdue' not in existing_pref_cols:
            batch_op.add_column(sa.Column('notify_overdue', sa.Boolean(), nullable=True, server_default='1'))
        if 'notify_mock_tests' not in existing_pref_cols:
            batch_op.add_column(sa.Column('notify_mock_tests', sa.Boolean(), nullable=True, server_default='1'))

    # 3. Create user_device_tokens table if not exists
    if 'user_device_tokens' not in existing_tables:
        op.create_table(
            'user_device_tokens',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('token', sa.String(length=500), nullable=False),
            sa.Column('platform', sa.String(length=20), server_default='android', nullable=True),
            sa.Column('device_info', sa.String(length=255), nullable=True),
            sa.Column('is_active', sa.Boolean(), server_default='1', nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.Column('last_seen_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        with op.batch_alter_table('user_device_tokens', schema=None) as batch_op:
            batch_op.create_index(batch_op.f('ix_user_device_tokens_token'), ['token'], unique=False)
            batch_op.create_index(batch_op.f('ix_user_device_tokens_user_id'), ['user_id'], unique=False)

    # 4. Create study_plan_recommendations table if not exists
    if 'study_plan_recommendations' not in existing_tables:
        op.create_table(
            'study_plan_recommendations',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('plan_date', sa.String(length=20), nullable=False),
            sa.Column('recommendation_text', sa.Text(), nullable=False),
            sa.Column('reasoning_summary', sa.Text(), nullable=True),
            sa.Column('task_references', sa.Text(), nullable=True),
            sa.Column('source', sa.String(length=50), server_default='grok', nullable=True),
            sa.Column('is_active', sa.Boolean(), server_default='1', nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        with op.batch_alter_table('study_plan_recommendations', schema=None) as batch_op:
            batch_op.create_index(batch_op.f('ix_study_plan_recommendations_plan_date'), ['plan_date'], unique=False)
            batch_op.create_index(batch_op.f('ix_study_plan_recommendations_user_id'), ['user_id'], unique=False)

    # 5. Create scheduled_notifications table if not exists
    if 'scheduled_notifications' not in existing_tables:
        op.create_table(
            'scheduled_notifications',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('task_id', sa.String(length=36), nullable=True),
            sa.Column('notification_type', sa.String(length=50), nullable=False),
            sa.Column('title', sa.String(length=255), nullable=False),
            sa.Column('body', sa.Text(), nullable=False),
            sa.Column('scheduled_time', sa.DateTime(), nullable=False),
            sa.Column('status', sa.String(length=30), server_default='pending', nullable=True),
            sa.Column('sent_at', sa.DateTime(), nullable=True),
            sa.Column('error_message', sa.Text(), nullable=True),
            sa.Column('retry_count', sa.Integer(), server_default='0', nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['task_id'], ['tasks.id'], ondelete='SET NULL'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        with op.batch_alter_table('scheduled_notifications', schema=None) as batch_op:
            batch_op.create_index(batch_op.f('ix_scheduled_notifications_scheduled_time'), ['scheduled_time'], unique=False)
            batch_op.create_index(batch_op.f('ix_scheduled_notifications_status'), ['status'], unique=False)
            batch_op.create_index(batch_op.f('ix_scheduled_notifications_task_id'), ['task_id'], unique=False)
            batch_op.create_index(batch_op.f('ix_scheduled_notifications_user_id'), ['user_id'], unique=False)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = Inspector.from_engine(bind)
    existing_tables = inspector.get_table_names()

    if 'scheduled_notifications' in existing_tables:
        op.drop_table('scheduled_notifications')
    if 'study_plan_recommendations' in existing_tables:
        op.drop_table('study_plan_recommendations')
    if 'user_device_tokens' in existing_tables:
        op.drop_table('user_device_tokens')

    with op.batch_alter_table('user_preferences', schema=None) as batch_op:
        batch_op.drop_column('notify_mock_tests')
        batch_op.drop_column('notify_overdue')
        batch_op.drop_column('notify_daily_plan')
        batch_op.drop_column('notify_study_reminders')
        batch_op.drop_column('timezone')
        batch_op.drop_column('quiet_hours_end')
        batch_op.drop_column('quiet_hours_start')
        batch_op.drop_column('preferred_planning_time')
        batch_op.drop_column('reminder_lead_time_minutes')

    with op.batch_alter_table('tasks', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_tasks_import_batch_id'))
        batch_op.drop_column('import_batch_id')
        batch_op.drop_column('session_type')
        batch_op.drop_column('weekday')
        batch_op.drop_column('end_time')
        batch_op.drop_column('start_time')
