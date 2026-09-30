from fastapi import HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class APIError(HTTPException):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        self.code = code
        super().__init__(status_code=status_code, detail=message)


def error_body(code: str, message: str, status: int) -> dict:
    return {"error": {"code": code, "message": message, "status": status}}


async def api_error_handler(_: Request, exc: APIError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=error_body(exc.code, str(exc.detail), exc.status_code),
    )


async def http_error_handler(_: Request, exc: HTTPException) -> JSONResponse:
    if isinstance(exc, APIError):
        return await api_error_handler(_, exc)
    code = "HTTP_ERROR"
    if exc.status_code == 401:
        code = "UNAUTHORIZED"
    elif exc.status_code == 403:
        code = "FORBIDDEN"
    elif exc.status_code == 404:
        code = "NOT_FOUND"
    return JSONResponse(
        status_code=exc.status_code,
        content=error_body(code, str(exc.detail), exc.status_code),
    )


async def validation_error_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    message = "; ".join(
        f"{'.'.join(str(p) for p in e.get('loc', []))}: {e.get('msg')}" for e in exc.errors()
    )
    return JSONResponse(
        status_code=422,
        content=error_body("VALIDATION_ERROR", message, 422),
    )
