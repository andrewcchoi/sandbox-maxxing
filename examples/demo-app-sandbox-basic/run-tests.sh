#!/bin/bash

# Test Runner for Demo Blog Application
# Runs both backend (pytest) and frontend (Jest) tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
BACKEND_ONLY=false
FRONTEND_ONLY=false
COVERAGE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --backend-only)
      BACKEND_ONLY=true
      shift
      ;;
    --frontend-only)
      FRONTEND_ONLY=true
      shift
      ;;
    --coverage)
      COVERAGE=true
      shift
      ;;
    --help)
      echo "Usage: ./run-tests.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --backend-only   Run only backend tests (pytest)"
      echo "  --frontend-only  Run only frontend tests (Jest)"
      echo "  --coverage       Generate coverage reports"
      echo "  --help           Show this help message"
      echo ""
      echo "Examples:"
      echo "  ./run-tests.sh                    # Run all tests"
      echo "  ./run-tests.sh --backend-only     # Run only backend tests"
      echo "  ./run-tests.sh --coverage         # Run all tests with coverage"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Function to print section headers
print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
}

# Function to print success message
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
  echo -e "${RED}✗ $1${NC}"
}

# Track overall test status
BACKEND_PASSED=true
FRONTEND_PASSED=true

# Run backend tests
if [ "$FRONTEND_ONLY" = false ]; then
  print_header "Running Backend Tests (pytest)"

  cd backend

  if [ "$COVERAGE" = true ]; then
    if pytest --cov=app --cov-report=term-missing --cov-report=html; then
      print_success "Backend tests passed"
      echo -e "${YELLOW}Coverage report generated at: backend/htmlcov/index.html${NC}"
    else
      print_error "Backend tests failed"
      BACKEND_PASSED=false
    fi
  else
    if pytest; then
      print_success "Backend tests passed"
    else
      print_error "Backend tests failed"
      BACKEND_PASSED=false
    fi
  fi

  cd ..
fi

# Run frontend tests
if [ "$BACKEND_ONLY" = false ]; then
  print_header "Running Frontend Tests (Jest)"

  cd frontend

  if [ "$COVERAGE" = true ]; then
    if npm test -- --coverage --run; then
      print_success "Frontend tests passed"
      echo -e "${YELLOW}Coverage report generated at: frontend/coverage/index.html${NC}"
    else
      print_error "Frontend tests failed"
      FRONTEND_PASSED=false
    fi
  else
    if npm test -- --run; then
      print_success "Frontend tests passed"
    else
      print_error "Frontend tests failed"
      FRONTEND_PASSED=false
    fi
  fi

  cd ..
fi

# Print summary
print_header "Test Summary"

if [ "$FRONTEND_ONLY" = false ]; then
  if [ "$BACKEND_PASSED" = true ]; then
    print_success "Backend: All tests passed"
  else
    print_error "Backend: Some tests failed"
  fi
fi

if [ "$BACKEND_ONLY" = false ]; then
  if [ "$FRONTEND_PASSED" = true ]; then
    print_success "Frontend: All tests passed"
  else
    print_error "Frontend: Some tests failed"
  fi
fi

# Exit with appropriate status
if [ "$BACKEND_PASSED" = true ] && [ "$FRONTEND_PASSED" = true ]; then
  echo ""
  print_success "All tests passed!"
  exit 0
else
  echo ""
  print_error "Some tests failed"
  exit 1
fi
