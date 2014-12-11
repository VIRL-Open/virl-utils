#!/usr/bin/env python
import logging, os, sys, pprint, subprocess
import salt.client

if os.geteuid() != 0:
        print "run this as root / with sudo"
        sys.exit()



LOG = logging.getLogger()
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('%(asctime)s %(module)s %(message)s'))
LOG.addHandler(handler)
LOG.setLevel(logging.DEBUG)

LOG.info('Salt version is %s', salt.__version__)

client = salt.client.Caller('/etc/salt/minion.cfg')

LOG.info('Salt caller minion created with functions: %s',
         hasattr(client.sminion, "functions"))

LOG.info('Config is OK (%s, %s)',
         client.function('config.get', 'master_sign_key_name'),
         client.function('config.get', 'verify_master_pubkey_sign'))
LOG.info('Ping returned: %s', client.function('test.ping'))

LOG.info('NTPq is\n%s', subprocess.check_output(['ntpq', '-np']))

