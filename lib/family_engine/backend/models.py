from sqlalchemy import Column, String, Numeric, Boolean, Date, DateTime, ForeignKey, Enum as SQLEnum, func
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum

Base = declarative_base()

class FamilyRoleEnum(str, enum.Enum):
    OWNER = "owner"
    ADULT = "adult"
    CHILD = "child"
    GUEST = "guest"

class MemberStatusEnum(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    DECLINED = "declined"

class Family(Base):
    __tablename__ = "families"

    family_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    photo_url = Column(String)
    invite_code = Column(String(20), unique=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    members = relationship("FamilyMember", back_populates="family", cascade="all, delete-orphan")
    budgets = relationship("FamilyBudget", back_populates="family", cascade="all, delete-orphan")
    goals = relationship("FamilyGoal", back_populates="family", cascade="all, delete-orphan")

class FamilyMember(Base):
    __tablename__ = "family_members"

    family_id = Column(UUID(as_uuid=True), ForeignKey("families.family_id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(String(50), primary_key=True)
    role = Column(SQLEnum(FamilyRoleEnum), default=FamilyRoleEnum.ADULT, nullable=False)
    status = Column(SQLEnum(MemberStatusEnum), default=MemberStatusEnum.PENDING, nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    family = relationship("Family", back_populates="members")

class FamilyBudget(Base):
    __tablename__ = "family_budgets"

    budget_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    family_id = Column(UUID(as_uuid=True), ForeignKey("families.family_id", ondelete="CASCADE"), nullable=False)
    category = Column(String(50), nullable=False)
    limit_amount = Column(Numeric(12, 2), nullable=False)
    month = Column(String(7), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    family = relationship("Family", back_populates="budgets")

class FamilyGoal(Base):
    __tablename__ = "family_goals"

    goal_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    family_id = Column(UUID(as_uuid=True), ForeignKey("families.family_id", ondelete="CASCADE"), nullable=False)
    title = Column(String(100), nullable=False)
    target_amount = Column(Numeric(12, 2), nullable=False)
    saved_amount = Column(Numeric(12, 2), default=0.0)
    deadline = Column(Date)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    family = relationship("Family", back_populates="goals")
