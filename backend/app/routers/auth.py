from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User
from app.schemas import LoginRequest, RegisterRequest, TokenResponse, UserOut
from app.security import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register", response_model=UserOut, status_code=status.HTTP_201_CREATED
)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> User:
    email = str(payload.email).strip().lower()

    if db.scalar(select(User.id).where(User.email == email)) is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Există deja un cont cu acest email.",
        )

    # Primul cont real (cu parolă) devine admin. Utilizatorii vechi fără
    # parolă, rămași din etapa single-user, nu contează.
    first_account = (
        db.scalar(
            select(User.id).where(User.password_hash.is_not(None)).limit(1)
        )
        is None
    )
    user = User(
        email=email,
        password_hash=hash_password(payload.password),
        role="admin" if first_account else "user",
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Există deja un cont cu acest email.",
        )
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    email = str(payload.email).strip().lower()
    user = db.scalar(select(User).where(User.email == email))

    # Același mesaj pentru email inexistent și parolă greșită.
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Email sau parolă incorecte.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return TokenResponse(
        access_token=create_access_token(user.id),
        token_type="bearer",
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user
