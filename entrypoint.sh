#!/bin/sh

set -e

# setup ssh-private-key
mkdir -p /root/.ssh/
echo "$INPUT_DEPLOY_KEY" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# setup deploy git account
git config --global user.name "$INPUT_USER_NAME"
git config --global user.email "$INPUT_USER_EMAIL"

# install pandoc 
apt-get install wget
wget https://github.com/jgm/pandoc/releases/download/2.12/pandoc-2.12-1-amd64.deb
dpkg -i pandoc-2.12-1-amd64.deb

# install hexo env
# follow https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
# mkdir -p ~/.npm-global/lib
# npm config set prefix '~/.npm-global'
# npm install npm --global
# export PATH=~/.npm-global/bin:$PATH
# NPM_CONFIG_PREFIX=~/.npm-global
npm config set unsafe-perm true

npm install hexo-cli -g
npm install hexo-deployer-git --save

# deployment
if [ "$INPUT_COMMIT_MSG" = "none" ]
then
    hexo g
    cp -rf source/_drafts/private/* public/
    hexo d
elif [ "$INPUT_COMMIT_MSG" = "hide" ]
then
    hexo g
    cd public
    find . -path "./20*" -name "*.html" | awk '{printf("cp ../source/_drafts/WrongDoor.html %s\n",$0)}' | bash
    cd images
    find . -regex "\./.*/.*" | awk '{printf("cp NeverGonnaGiveYouUp.jpg %s\n",$0)}' | bash
    cd ../..
    hexo d
elif [ "$INPUT_COMMIT_MSG" = "" ] || [ "$INPUT_COMMIT_MSG" = "default" ]
then
    # pull original publish repo
    NODE_PATH=$NODE_PATH:$(pwd)/node_modules node /sync_deploy_history.js
    hexo g -d
else
    NODE_PATH=$NODE_PATH:$(pwd)/node_modules node /sync_deploy_history.js
    hexo g -d -m "$INPUT_COMMIT_MSG"
fi

echo ::set-output name=notify::"Deploy complete."