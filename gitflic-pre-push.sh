#!/bin/bash

# Токен для доступа к API
GITFLIC_TOKEN="TOKEN"
# Тип владельца проекта - USER, TEAM или COMPANY
OWNER_TYPE="USER"

echo "Pre-push hook is running..."

REMOTE_URL=$(git remote get-url origin)

if [[ "$REMOTE_URL" =~ ^git@ ]]; then
    if [[ "$REMOTE_URL" =~ gitflic.ru ]]; then
        GITFLIC_URL="https://api.gitflic.ru"
    else
        GITFLIC_URL=$(echo "$REMOTE_URL" | sed -E 's/^git@(.*):.*$/https:\/\/\1\/rest-api/')
    fi
    OWNER_ALIAS=$(echo "$REMOTE_URL" | sed -E 's/^git@.*:(.*)\/.*/\1/')
    REPO_ALIAS=$(echo "$REMOTE_URL" | sed -E 's/^git@.*:(.*)\/(.*)\.git/\2/')
elif [[ "$REMOTE_URL" =~ ^https:// ]]; then
    if [[ "$REMOTE_URL" =~ gitflic.ru ]]; then
        GITFLIC_URL="https://api.gitflic.ru"
    else
        GITFLIC_URL=$(echo "$REMOTE_URL" | sed -E 's|^(https://[^/]+)/project/.*|\1/rest-api|')
    fi
    OWNER_ALIAS=$(echo "$REMOTE_URL" | sed -E 's|^.*/project/([^/]+)/.*|\1|')
    REPO_ALIAS=$(echo "$REMOTE_URL" | sed -E 's|^.*/project/[^/]+/(.*)\.git|\1|')
else
    echo "Ошибка: Неподдерживаемый формат REMOTE URL."
    exit 1
fi

echo "Debug: REMOTE_URL=$REMOTE_URL"
echo "Debug: GITFLIC_URL=$GITFLIC_URL"
echo "Debug: OWNER_ALIAS=$OWNER_ALIAS"
echo "Debug: REPO_ALIAS=$REPO_ALIAS"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITFLIC_TOKEN" \
    "$GITFLIC_URL/project/$OWNER_ALIAS/$REPO_ALIAS")

if [ "$HTTP_STATUS" -eq 404 ]; then
    echo "Репозиторий не найден, создаем новый..."

    CREATE_REPO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$GITFLIC_URL/project" \
        -H "Authorization: token $GITFLIC_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "'"$REPO_ALIAS"'",
            "isPrivate": true,
            "alias": "'"$REPO_ALIAS"'",
            "ownerAlias": "'"$OWNER_ALIAS"'",
            "ownerAliasType": "'"$OWNER_TYPE"'",
            "description": "Репозиторий создан автоматически при отправке пуша"
        }')

    if [ "$CREATE_REPO_RESPONSE" -eq 200 ]; then
        echo "Репозиторий успешно создан."
    elif [ "$CREATE_REPO_RESPONSE" -eq 403 ]; then
        echo "Ошибка: Недостаточно прав для создания репозитория."
        exit 1
    elif [ "$CREATE_REPO_RESPONSE" -eq 422 ]; then
        echo "Ошибка: Запрос содержит неподдерживаемые значения."
        exit 1
    else
        echo "Ошибка: Не удалось создать репозиторий. Код ошибки: $CREATE_REPO_RESPONSE"
        exit 1
    fi
    
elif [ "$HTTP_STATUS" -eq 403 ]; then
    echo "Ошибка: Недействительный токен API." 
    exit 1 
elif [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Репозиторий уже существует."
fi

git push "$@"