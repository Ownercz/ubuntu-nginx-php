trap "postfix stop" SIGINT
trap "postfix stop" SIGTERM
trap "postfix reload" SIGHUP

# ensure postfix queue directories exist and are writable
mkdir -p /var/spool/postfix/etc

# force new copy of hosts there (otherwise links could be outdated)
cp /etc/hosts /var/spool/postfix/etc/hosts

# attempt to create any missing queue directories
if ! postfix check >/dev/null 2>&1; then
  # fall back to manual creation of basic queue dirs if needed
  mkdir -p \
    /var/spool/postfix/active \
    /var/spool/postfix/bounce \
    /var/spool/postfix/corrupt \
    /var/spool/postfix/defer \
    /var/spool/postfix/deferred \
    /var/spool/postfix/flush \
    /var/spool/postfix/hold \
    /var/spool/postfix/incoming \
    /var/spool/postfix/maildrop \
    /var/spool/postfix/saved \
    /var/spool/postfix/private \
    /var/spool/postfix/public \
    /var/spool/postfix/pid
fi

# (re)build postfix maps so *.db files always exist
postmap /etc/postfix/sasl_passwd 2>/dev/null || true
postmap /etc/postfix/generic 2>/dev/null || true
postmap /etc/postfix/relayhost_map 2>/dev/null || true
postmap /etc/postfix/virtual 2>/dev/null || true
newaliases 2>/dev/null || true

# start postfix
postfix start

# lets give postfix some time to start
sleep 3

# wait until postfix is dead (triggered by trap)
while kill -0 "`cat /var/spool/postfix/pid/master.pid`"; do
  sleep 5
done
