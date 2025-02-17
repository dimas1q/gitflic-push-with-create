# Скрипт для автоматического создания репозитория при пуше в GitFlic

Данный скрипт позволяет настроить автоматическое создание репозитория в GitFlic при пуше

## Использование

**1.** Загрузите gitflic-pre-push.sh из репозитория и поместите в любую удобную директорию (например, в домашнюю)

Отредактируйте скрипт: в параметре GITFLIC_TOKEN укажите ваш токен API, в параметре OWNER_TYPE укажите тип владельца репозитория, который необходимо создать при его отсутствии:

``` bash
# Токен для доступа к API
GITFLIC_TOKEN="TOKEN"
# Тип владельца проекта - USER, TEAM или COMPANY
OWNER_TYPE="USER"
```

**2.** Сделайте скрипт исполняемым

``` bash
chmod +x ~/gitflic-pre-push.sh
```

**3.** Добавьте новую команду `push-with-create` в git (указываем для команды путь к .sh файлу):

``` bash
git config --global alias.push-with-create '!f() { ~/gitflic-pre-push.sh "$@"; }; f'
```

**4.** Выполните `git init`, сделайте коммит, и добавьте remote в вашем репозитории

**5.** Выполняйте первый пуш командой:

``` bash
git push-with-create --set-upstream origin main
```

или (если upstream уже настроен):

``` bash
git push-with-create
```

Скрипт сработает для любой версии GitFlic (облачная или Self-Hosted) и поддерживает HTTPS/SSH Remote.
