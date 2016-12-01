#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
from time import sleep
import requests
import logging
from logging import StreamHandler
import textwrap
import sys

# Define some global variables
USERNAME = "guest"
PASSWORD = "guest"

# will sleep for MAX_WAIT / INTERVAL when waiting
MAX_WAIT = 300
INTERVAL = 30 

# The background is set with 40 plus the number of the color,
# and the foreground with 30.
BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = range(8)


class ColorHandler(StreamHandler):
    """
    Add colors to logging output
    partial credits to
    http://opensourcehacker.com/2013/03/14/ultima-python-logger-somewhere-over-the-rainbow/
    """

    def __init__(self, colored):
        super(ColorHandler, self).__init__()
        self.colored = colored

    COLORS = {
        'WARNING': YELLOW,
        'INFO': WHITE,
        'DEBUG': BLUE,
        'CRITICAL': YELLOW,
        'ERROR': RED
    }

    RESET_SEQ = "\033[0m"
    COLOR_SEQ = "\033[1;%dm"
    BOLD_SEQ = "\033[1m"

    level_map = {
        logging.DEBUG: (None, CYAN, False),
        logging.INFO: (None, WHITE, False),
        logging.WARNING: (None, YELLOW, True),
        logging.ERROR: (None, RED, True),
        logging.CRITICAL: (RED, WHITE, True),
    }

    def addColor(self, text, bg, fg, bold):
        ctext = ''
        if bg is not None:
            ctext = self.COLOR_SEQ % (40 + bg)
        if bold:
            ctext = ctext + self.BOLD_SEQ
        ctext = ctext + self.COLOR_SEQ % (30 + fg) + text + self.RESET_SEQ
        return ctext

    def colorize(self, record):
        if record.levelno in self.level_map:
            bg, fg, bold = self.level_map[record.levelno]
        else:
            bg, fg, bold = None, WHITE, False

        # exception?
        if record.exc_info:
            formatter = logging.Formatter(format)
            record.exc_text = self.addColor(
                formatter.formatException(record.exc_info), bg, fg, bold)

        record.msg = self.addColor(str(record.msg), bg, fg, bold)
        return record

    def format(self, record):
        if self.colored:
            message = logging.StreamHandler.format(self, self.colorize(record))
        else:
            message = logging.StreamHandler.format(self, record)
        return message


class VIRLConfig(object):
    ''' holds configuration information needed by all the functions '''

    def __init__(self, logger, user, password, host, port=19399,
                 timeout=MAX_WAIT, packets=1000, pcapfilter='',
                 sim_id=None, sim_node=None, sim_intfc=None):
        super(VIRLConfig, self).__init__()
        self.host = host
        self.port = port
        self.timeout = timeout
        self.interval = timeout // INTERVAL
        self.sim_id = sim_id
        self.sim_node = sim_node
        self.sim_intfc = sim_intfc
        self.logger = logger
        self.packets = packets
        self.filter = pcapfilter

        self.session = requests.Session()
        self.session.auth = (user, password)

    def _url(self, method=''):
        '''return the proper URL given the global vars and the
        method parameter.
        '''
        return "http://{}:{}/simengine/rest/{}".format(self.host,
                                                       self.port,
                                                       method)

    def _request(self, verb, method, *args, **kwargs):
        r = self.session.request(verb, self._url(method), *args, **kwargs)
        if not r.ok:
            cfg.logger.error('VIRL API [%s]: %s', r.status_code, r.json().get('cause'))
        return r

    def post(self, method, *args, **kwargs):
        return self._request('POST', method, *args, **kwargs)

    def get(self, method, *args, **kwargs):
        return self._request('GET', method, *args, **kwargs)


def startSim(cfg, filename):
    '''This function will start a simulation using the provided .virl file
    '''
    cfg.logger.warn('Simulation start...')

    # Open .virl file and assign it to the variable
    with open(filename, 'rb') as virl_file:
        # Parameter which will be passed to the server with the API call
        simulation_name = 'captureme'
        params = dict(file=simulation_name)

        # Make an API call and assign the response information to the variable
        r = cfg.post('launch', params=params, data=virl_file)

        # Check if call was successful, if true log it and return the value
        if r.status_code == 200:
            cfg.sim_id = r.text
            cfg.logger.info(
                'Simulation has been started, sim id [%s]', cfg.sim_id)
    return r.ok


def waitForSimStart(cfg):
    '''Returns True if the sim is started and all nodes
    are active/reachable
    waits for cfg.max_wait (default 5min)
    '''
    waited = 0
    active = False

    cfg.logger.warn('Waiting for Simulation to become active...')

    while not active and waited < cfg.timeout:

        # Make an API call and assign the response information to the
        # variable
        r = cfg.get('nodes/%s' % cfg.sim_id)
        if not r.ok:
            return False

        # check if all nodes are active AND reachable
        nodes = r.json()[cfg.sim_id]
        for node in nodes.values():
            if not (node.get('state') == 'ACTIVE' and node.get('reachable')):
                active = False
                break
            else:
                active = True

        # wait if not
        if not active:
            sleep(cfg.interval)
            waited = waited + cfg.interval

    if active:
        cfg.logger.warn("Simulation is active.")
    else:
        cfg.logger.error("Timeout... aborting!")

    return active


def getInterfaceId(cfg):
    '''get the interface index we're looking for
    '''
    cfg.logger.warn("Getting interface id from name [%s]...", cfg.sim_intfc)

    # Parameters which will be passed to the server with the API call
    params = dict(simulation=cfg.sim_id, nodes=cfg.sim_node)

    # Make an API call and assign the response information to the variable
    r = cfg.get('interfaces/%s' % cfg.sim_id, params=params)
    if r.ok:
        interfaces = r.json().get(cfg.sim_id).get(cfg.sim_node)
        if interfaces is None:
            cfg.logger.error('node not found: %s', cfg.sim_node)
            return None

        for key, interface in interfaces.items():
            if interface.get('name') == cfg.sim_intfc:
                cfg.logger.info("Found id: %s", key)
                return key

    cfg.logger.error("Can't find specified interface %s", cfg.sim_intfc)
    return None


def createCapture(cfg):
    '''Create a packet capture for the simulation using the given
    parameters in cfg
    '''
    cfg.logger.warn("Starting packet capture...")

    # get interface based on name
    retval = None
    interface = getInterfaceId(cfg)
    if interface is not None:
        params = dict(simulation=cfg.sim_id, node=cfg.sim_node,
                      interface=interface, count=cfg.packets)
        params['pcap-filter'] = cfg.pcapfilter
        r = cfg.post('capture/%s' % cfg.sim_id, params=params)
        # did it work?
        if r.ok:
            retval = list(r.json().keys())[0]
            cfg.logger.warn("Created packet capture (%s)", retval)
    return retval


def waitForCapture(cfg, id):
    '''Wait until the packet capture is done. check for the 'running'
    state every 10 seconds.
    '''
    waited = 0
    done = False

    cfg.logger.warn('Waiting for capture to finish...')

    while not done and waited < cfg.timeout:

        # Make an API call and assign the response information to the
        # variable
        r = cfg.get('capture/%s' % cfg.sim_id)
        if not r.ok:
            return False

        # check if all nodes are active AND reachable
        captures = r.json()
        for cid, cval in captures.items():
            if cid == id and not cval.get('running'):
                done = True
                break

        # wait if not
        if not done:
            sleep(cfg.interval)
            waited = waited + cfg.interval

    if done:
        cfg.logger.warn("Capture has finished.")
    else:
        cfg.logger.error("Timeout... aborting!")

    return done


def downloadCapture(cfg, id):
    '''Download the finished capture and write it into a file
    '''
    content = 'application/vnd.tcpdump.pcap'
    params = dict(capture=id)
    headers = dict(accept=content)
    cfg.logger.warn('Downloading capture file...')

    # Make an API call and assign the response information to the
    # variable
    r = cfg.get('capture/%s' % cfg.sim_id, params=params, headers=headers)
    if r.status_code == 200 and r.headers.get('content-type') == content:
        # "ContentDisposition":
        # "attachment; filename=V1_GigabitEthernet0_1_2016-10-15-17-18-18.pcap
        filename = r.headers.get('Content-Disposition').split('=')[1]
        with open(filename, "wb") as fh:
            fh.write(r.content)
    else:
        cfg.logger.error("problem... %s", r.headers)
    cfg.logger.warn("Download finished.")


def stopSim(cfg):
    '''This function will stop the simulation specified in cfg
    '''
    cfg.logger.warn('Simulation stop...')

    # Make an API call and assign the response information to the variable
    r = cfg.get('stop/%s' % cfg.sim_id)

    # Check if call was successful, if true log it and exit the application
    if r.status_code == 200:
        cfg.logger.info('Simulation [%s] stop initiated.', cfg.sim_id)


def main():

    description = textwrap.dedent('''\
    %(prog)s starts the given simulation and waits until it is fully active.
    It then creates a packet capture on the given interface (with optional
    pcap filter), waits until the given amount of packets have been received.
    It then downloads the resulting pcap file and shuts down the simulation.

    At least the VIRL host, the filename, node- and interface name and the
    packet count have to be provided. 

    Username, password and filter are optional.
    ''')

    epilog = textwrap.dedent('''\
    Example:
    %(prog)s 172.16.1.1 topo.virl router-1 GigabitEthernet1 100
    %(prog)s 172.16.1.1 -l2 example.virl iosv-1 GigabitEthernet0/1
    ''')

    parser = argparse.ArgumentParser(description=description, epilog=epilog,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('host', help="remote host")
    parser.add_argument('filename', help="VIRL topology file")
    parser.add_argument('nodename', help="node name")
    parser.add_argument('interface', help="interface name")
    parser.add_argument('counter', help="packet count (default is 25)", 
                        type=int, nargs='?', default=25)
    parser.add_argument('--filter', '-f', default='',
                        help="pcap packet filter")
    parser.add_argument('--loglevel', '-l', type=int, choices=range(0, 5),
                        default=3, help="loglevel, 0-4 (default is 3)")
    parser.add_argument('--user', '-u', default=USERNAME,
                        help="user name on remote host")
    parser.add_argument('--password', '-p', default=PASSWORD,
                        help="password on remote host")
    parser.add_argument('--maxwait', '-m', default=MAX_WAIT,
                        type=int, help="maximum time to wait")
    parser.add_argument('--nocolor', '-n', action='store_true',
                        help="don't use colors for logging")
    args = parser.parse_args()

    # setup logging
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.CRITICAL - (args.loglevel) * 10)
    handler = ColorHandler(colored=(not args.nocolor))
    formatter = logging.Formatter("==> %(asctime)s: %(message)s", datefmt='%Y-%m-%d,%H:%M:%S')
    handler.setFormatter(formatter)
    root_logger.addHandler(handler)

    # use for the configuration & parameters for the capture
    virl = VIRLConfig(root_logger, args.user, args.password, 
                      args.host, timeout=args.maxwait)
    virl.sim_node = args.nodename
    virl.sim_intfc = args.interface
    virl.packets = args.counter
    virl.pcapfilter = args.filter

    retval = -1
    root_logger.warn('Starting...')
    if startSim(virl, args.filename):
        try:
            if waitForSimStart(virl):
                capId = createCapture(virl)
                if capId is not None and waitForCapture(virl, capId):
                    downloadCapture(virl, capId)
                    retval = 0
        except KeyboardInterrupt:
            pass
        finally:
            stopSim(virl)
    return retval

if __name__ == '__main__':
    sys.exit(main())