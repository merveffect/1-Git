#!/bin/bash
set -e

echo "Starting Data Pipeline Monitor..."

# Start backend
cd "$(dirname "$0")/backend"
if [ ! -d ".venv" ]; then
  echo "Creating Python virtual environment..."
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r requirements.txt
uvicorn main:app --reload --port 8000 &
BACKEND_PID=$!
cd ..

# Start frontend
cd "$(dirname "$0")/frontend"
echo "Installing/updating frontend dependencies..."
npm install --silent
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "Data Pipeline Monitor is running:"
echo "  Backend:  http://localhost:8000"
echo "  Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop"

cleanup() {
  kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
  exit 0
}
trap cleanup INT TERM
wait
