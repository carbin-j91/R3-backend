# 1. 베이스 이미지 설정 (Python 3.11 슬림 버전)
FROM python:3.11-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 시스템 패키지 업데이트 및 poetry 설치
# --no-cache-dir 옵션으로 불필요한 캐시를 남기지 않아 이미지 용량을 줄입니다.
RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    && pip install --no-cache-dir poetry

# 4. 의존성 파일 복사 및 설치
# pyproject.toml과 poetry.lock 파일이 변경되었을 때만 이 단계를 다시 실행하여 빌드 캐시를 효율적으로 사용합니다.
COPY pyproject.toml poetry.lock* /app/

# --no-root 옵션은 가상 환경을 프로젝트 폴더 내에 생성하도록 합니다.
# --without dev 옵션으로 개발용 의존성은 제외하고 설치합니다. (프로덕션 환경 고려)
RUN poetry config virtualenvs.in-project true && \
    poetry install --no-root --without dev

# 5. 소스 코드 복사
# .dockerignore 파일을 활용하여 불필요한 파일(예: .venv, .vscode)은 복사에서 제외합니다.
COPY . /app

# 6. 컨테이너 실행 시 FastAPI 앱 구동
# docker-compose.yml에서 command를 오버라이드하므로, 여기서는 기본 실행 명령을 명시합니다.
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]