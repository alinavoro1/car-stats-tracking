from pathlib import Path

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse

STATIC_DIR = Path(__file__).resolve().parents[2] / "static"
APK_PATH = STATIC_DIR / "car-tracker-test.apk"
PAGE_PATH = STATIC_DIR / "download.html"

router = APIRouter(tags=["download"])


@router.get("/download", include_in_schema=False)
def download_page() -> FileResponse:
    if not PAGE_PATH.exists():
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Pagina nu există.")
    return FileResponse(PAGE_PATH, media_type="text/html")


@router.get("/download/car-tracker-test.apk", include_in_schema=False)
def download_apk() -> FileResponse:
    if not APK_PATH.exists():
        raise HTTPException(status.HTTP_404_NOT_FOUND, "APK indisponibil.")
    return FileResponse(
        APK_PATH,
        media_type="application/vnd.android.package-archive",
        filename="car-tracker-test.apk",
    )
