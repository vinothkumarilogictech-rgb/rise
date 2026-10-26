"""initial_schema

Revision ID: 6757ea163043
Revises: 
Create Date: 2026-10-25 12:33:08.297453

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6757ea163043'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. users
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('display_name', sa.String(length=100), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)

    # 2. user_preferences
    op.create_table(
        'user_preferences',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False),
        sa.Column('available_daily_minutes', sa.Integer(), server_default='120', nullable=True),
        sa.Column('planning_style', sa.String(length=50), server_default='balanced', nullable=True),
        sa.Column('reminder_time', sa.String(length=10), server_default='08:00', nullable=True),
        sa.Column('fcm_token', sa.String(length=255), nullable=True),
        sa.Column('notification_enabled', sa.Boolean(), server_default='true', nullable=True),
        sa.Column('theme', sa.String(length=30), server_default='dark', nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
    )

    # 3. goals
    op.create_table(
        'goals',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('category', sa.String(length=100), server_default='General', nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('target_date', sa.String(length=30), nullable=True),
        sa.Column('status', sa.String(length=30), server_default='active', nullable=True),
        sa.Column('progress_percentage', sa.Float(), server_default='0.0', nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_goals_user_id'), 'goals', ['user_id'], unique=False)
    op.create_index(op.f('ix_goals_category'), 'goals', ['category'], unique=False)

    # 4. goal_milestones
    op.create_table(
        'goal_milestones',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('goal_id', sa.String(length=36), sa.ForeignKey('goals.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('is_completed', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_goal_milestones_goal_id'), 'goal_milestones', ['goal_id'], unique=False)

    # 5. tasks
    op.create_table(
        'tasks',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('goal_id', sa.String(length=36), sa.ForeignKey('goals.id', ondelete='SET NULL'), nullable=True),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('category', sa.String(length=100), server_default='General', nullable=True),
        sa.Column('section', sa.String(length=50), server_default='Main Priorities', nullable=True),
        sa.Column('priority', sa.String(length=20), server_default='medium', nullable=True),
        sa.Column('estimated_minutes', sa.Integer(), server_default='25', nullable=True),
        sa.Column('xp_reward', sa.Integer(), server_default='10', nullable=True),
        sa.Column('is_completed', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('due_date', sa.String(length=30), nullable=True),
        sa.Column('why_it_matters', sa.Text(), nullable=True),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_tasks_user_id'), 'tasks', ['user_id'], unique=False)
    op.create_index(op.f('ix_tasks_goal_id'), 'tasks', ['goal_id'], unique=False)
    op.create_index(op.f('ix_tasks_due_date'), 'tasks', ['due_date'], unique=False)

    # 6. task_completions
    op.create_table(
        'task_completions',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('task_id', sa.String(length=36), sa.ForeignKey('tasks.id', ondelete='CASCADE'), nullable=False),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('xp_awarded', sa.Integer(), server_default='10', nullable=True),
    )
    op.create_index(op.f('ix_task_completions_task_id'), 'task_completions', ['task_id'], unique=False)
    op.create_index(op.f('ix_task_completions_user_id'), 'task_completions', ['user_id'], unique=False)

    # 7. xp_transactions
    op.create_table(
        'xp_transactions',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('amount', sa.Integer(), nullable=False),
        sa.Column('source', sa.String(length=50), nullable=False),
        sa.Column('reference_id', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_xp_transactions_user_id'), 'xp_transactions', ['user_id'], unique=False)
    op.create_index(op.f('ix_xp_transactions_created_at'), 'xp_transactions', ['created_at'], unique=False)

    # 8. achievements
    op.create_table(
        'achievements',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('code', sa.String(length=50), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('description', sa.String(length=255), nullable=False),
        sa.Column('icon', sa.String(length=50), server_default='mountain', nullable=True),
        sa.Column('unlocked_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_achievements_user_id'), 'achievements', ['user_id'], unique=False)
    op.create_index(op.f('ix_achievements_code'), 'achievements', ['code'], unique=False)

    # 9. focus_sessions
    op.create_table(
        'focus_sessions',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('task_id', sa.String(length=36), sa.ForeignKey('tasks.id', ondelete='SET NULL'), nullable=True),
        sa.Column('label', sa.String(length=150), server_default='Deep Focus Session', nullable=True),
        sa.Column('planned_duration_minutes', sa.Integer(), server_default='25', nullable=True),
        sa.Column('actual_duration_minutes', sa.Integer(), server_default='25', nullable=True),
        sa.Column('completed', sa.Boolean(), server_default='true', nullable=True),
        sa.Column('xp_awarded', sa.Integer(), server_default='10', nullable=True),
        sa.Column('started_at', sa.DateTime(), nullable=True),
        sa.Column('ended_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_focus_sessions_user_id'), 'focus_sessions', ['user_id'], unique=False)

    # 10. journal_entries
    op.create_table(
        'journal_entries',
        sa.Column('id', sa.String(length=36), primary_key=True),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.String(length=10), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('prompts_answered', sa.Text(), nullable=True),
        sa.Column('mood', sa.String(length=30), server_default='focused', nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
    )
    op.create_index(op.f('ix_journal_entries_user_id'), 'journal_entries', ['user_id'], unique=False)
    op.create_index(op.f('ix_journal_entries_date'), 'journal_entries', ['date'], unique=False)


def downgrade() -> None:
    op.drop_table('journal_entries')
    op.drop_table('focus_sessions')
    op.drop_table('achievements')
    op.drop_table('xp_transactions')
    op.drop_table('task_completions')
    op.drop_table('tasks')
    op.drop_table('goal_milestones')
    op.drop_table('goals')
    op.drop_table('user_preferences')
    op.drop_table('users')
