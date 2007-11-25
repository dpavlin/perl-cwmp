ls -d queue/* | xargs -i sh -c "echo {} ; dq-list --dir {}"
