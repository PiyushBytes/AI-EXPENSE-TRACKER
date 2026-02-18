#!/bin/bash

# Security Audit Script for ExpenseAI
# Runs various security checks on the codebase

set -e

echo "========================================="
echo "ExpenseAI Security Audit"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Check 1: Environment variables
echo -e "\n${YELLOW}[1/8] Checking environment variables...${NC}"
if [ -f ".env" ]; then
    # Check for default/weak secrets
    if grep -q "CHANGE_THIS" .env; then
        echo -e "${RED}✗ Found default secrets in .env file${NC}"
        ERRORS=$((ERRORS+1))
    else
        echo -e "${GREEN}✓ No default secrets found${NC}"
    fi

    # Check for exposed .env in git
    if git ls-files --error-unmatch .env > /dev/null 2>&1; then
        echo -e "${RED}✗ .env file is tracked in git${NC}"
        ERRORS=$((ERRORS+1))
    else
        echo -e "${GREEN}✓ .env file not tracked in git${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No .env file found${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# Check 2: Dependency vulnerabilities
echo -e "\n${YELLOW}[2/8] Checking for dependency vulnerabilities...${NC}"
if command -v npm > /dev/null; then
    cd backend
    if npm audit --production > /dev/null 2>&1; then
        echo -e "${GREEN}✓ No npm vulnerabilities found${NC}"
    else
        echo -e "${RED}✗ npm vulnerabilities detected${NC}"
        npm audit --production
        ERRORS=$((ERRORS+1))
    fi
    cd ..
else
    echo -e "${YELLOW}⚠ npm not found, skipping${NC}"
    WARNINGS=$((WARNINGS+1))
fi

if command -v pip > /dev/null; then
    if [ -f "backend/requirements.txt" ]; then
        echo "Checking Python dependencies..."
        pip install safety > /dev/null 2>&1
        if safety check -r backend/requirements.txt > /dev/null 2>&1; then
            echo -e "${GREEN}✓ No Python vulnerabilities found${NC}"
        else
            echo -e "${RED}✗ Python vulnerabilities detected${NC}"
            safety check -r backend/requirements.txt
            ERRORS=$((ERRORS+1))
        fi
    fi
fi

# Check 3: Hardcoded secrets
echo -e "\n${YELLOW}[3/8] Scanning for hardcoded secrets...${NC}"
SECRET_PATTERNS=(
    "password\s*=\s*['\"][^'\"]*['\"]"
    "api_key\s*=\s*['\"][^'\"]*['\"]"
    "secret\s*=\s*['\"][^'\"]*['\"]"
    "token\s*=\s*['\"][^'\"]*['\"]"
)

FOUND_SECRETS=false
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" --include="*.ts" --include="*.js" --include="*.py" . > /dev/null 2>&1; then
        if [ "$FOUND_SECRETS" = false ]; then
            echo -e "${RED}✗ Potential hardcoded secrets found:${NC}"
            FOUND_SECRETS=true
            ERRORS=$((ERRORS+1))
        fi
        grep -r -i -E "$pattern" --include="*.ts" --include="*.js" --include="*.py" .
    fi
done

if [ "$FOUND_SECRETS" = false ]; then
    echo -e "${GREEN}✓ No hardcoded secrets found${NC}"
fi

# Check 4: Security headers configuration
echo -e "\n${YELLOW}[4/8] Checking security headers configuration...${NC}"
if [ -f "backend/src/middleware/security-headers.middleware.ts" ]; then
    echo -e "${GREEN}✓ Security headers middleware found${NC}"
else
    echo -e "${RED}✗ Security headers middleware not found${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check 5: CORS configuration
echo -e "\n${YELLOW}[5/8] Checking CORS configuration...${NC}"
if grep -r "cors.*\*" backend/ > /dev/null 2>&1; then
    echo -e "${RED}✗ Wildcard CORS detected${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ No wildcard CORS found${NC}"
fi

# Check 6: Authentication implementation
echo -e "\n${YELLOW}[6/8] Checking authentication implementation...${NC}"
AUTH_FILES_FOUND=true

if [ ! -f "backend/src/modules/auth/auth.service.ts" ] && [ ! -d "backend/app/api/v1" ]; then
    echo -e "${RED}✗ Authentication module not found${NC}"
    ERRORS=$((ERRORS+1))
    AUTH_FILES_FOUND=false
fi

if [ "$AUTH_FILES_FOUND" = true ]; then
    echo -e "${GREEN}✓ Authentication module found${NC}"
fi

# Check 7: Input validation
echo -e "\n${YELLOW}[7/8] Checking input validation...${NC}"
if grep -r "class-validator\|pydantic\|joi" backend/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Input validation library found${NC}"
else
    echo -e "${YELLOW}⚠ No input validation library detected${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# Check 8: Rate limiting
echo -e "\n${YELLOW}[8/8] Checking rate limiting configuration...${NC}"
if grep -r "throttler\|rate-limit\|slowapi" backend/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Rate limiting found${NC}"
else
    echo -e "${RED}✗ Rate limiting not detected${NC}"
    ERRORS=$((ERRORS+1))
fi

# Summary
echo -e "\n========================================="
echo -e "Security Audit Summary"
echo -e "========================================="
echo -e "Errors: ${RED}${ERRORS}${NC}"
echo -e "Warnings: ${YELLOW}${WARNINGS}${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "\n${GREEN}✓ All security checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "\n${YELLOW}⚠ Security audit completed with warnings${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Security audit failed with ${ERRORS} errors${NC}"
    echo -e "Please fix the issues and run the audit again."
    exit 1
fi
