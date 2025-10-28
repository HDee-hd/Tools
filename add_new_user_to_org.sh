#!/bin/bash

##############################################################
# Author: Hassan Dairo      ##################################
##   Script to add a new user to a GitHub organization  ######
# Usage: ./add_user_to_org.sh <username> <organization> [role]
##############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: $0 <username> <organization> [role]"
    echo "Roles: member (default) or admin"
    exit 1
fi

USERNAME=$1
ORG=$2
ROLE=${3:-member}  # Default to 'member' if not specified

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Validate role
if [[ "$ROLE" != "member" && "$ROLE" != "admin" ]]; then
    echo -e "${RED}Error: Invalid role. Must be 'member' or 'admin'${NC}"
    exit 1
fi

# Function to add user to organization
add_user_to_org() {
    echo -e "${YELLOW}Adding ${USERNAME} to ${ORG} organization as ${ROLE}...${NC}"

    # Using GitHub API via gh cli
    RESPONSE=$(gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/orgs/${ORG}/memberships/${USERNAME}" \
        -f role="${ROLE}" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully invited ${USERNAME} to ${ORG}!${NC}"
        echo -e "${YELLOW}The user will receive an invitation email.${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to add user to organization${NC}"
        echo "Error: $RESPONSE"
        return 1
    fi
}

# Function to verify organization membership
check_membership() {
    echo "Checking if user is already a member..."
    gh api "/orgs/${ORG}/members/${USERNAME}" &> /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}User ${USERNAME} is already a member of ${ORG}${NC}"
        read -p "Do you want to update their role? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 1  # Proceed with update
        else
            exit 0
        fi
    fi
    return 1  # Not a member, proceed
}

# Main execution
echo "==================="
echo "GitHub User Utility"
echo "==================="
echo ""

check_membership
add_user_to_org

if [ $? -eq 0 ]; then
    echo ""
    echo "Next steps:"
    echo "1. The user needs to accept the invitation"
    echo "2. Check pending invitations: gh api /orgs/${ORG}/invitations"
    echo "3. View all members: gh api /orgs/${ORG}/members"
fi

exit 0
