#!/usr/bin/env bash
echo "#!/usr/bin/env bash" > /tmp/cmds.sh
ls -la /Applications | grep '\->' | grep 'homebrew-cask' | awk -F ' -> ' '{print $2}' | echo "$(awk -F '/' '{printf  "unlink \"/Applications/%s\"; brew cask install --force %s;\n", $(NF), $5 }')" >> /tmp/cmds.sh
chmod u+x /tmp/cmds.sh
/tmp/cmds.sh
rm /tmp/cmds.sh
