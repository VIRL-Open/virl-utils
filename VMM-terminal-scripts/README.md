External Terminal Scripts for VM Maestro
========================================

# Introduction

VM Maestro is the desktop client application for interacting with Cisco's 
Virtual Internal Routing Lab, Personal Edition (VIRL PE), a network modeling 
and simulation environment.  Once you launch a network simulation in VIRL PE, 
you can right-click on an active node in the running simulation and select 
**Telnet... > to its Console Port**.  By default, VM Maestro will use its own 
built-in terminal emulator, opening a new view or pane within the VM Maestro GUI 
itself for this connection.  

As an experienced network engineer, you may have a terminal application that you 
would prefer to use instead.  Since the port numbers for the available 
connections change every time you start a simulation--unless you use static 
port numbers in your topology--it would be difficult to configure the connection 
to the simulated nodes yourself.  Instead, you can configure your VM Maestro 
preference to launch a separate terminal application that is installed on the 
same machine where you are running VM Maestro itself.     

All VM Maestro really does in this case is call the application just like you 
would on the CLI or command prompt on your local machine.  You will set the 
preferences to indicate the CLI that it should use to start the application and 
pass the *IP address* and *port* to the application to open a telnet or SSH 
connection.  If it works for your on the command line, then it should work when 
VM Maestro launches the application. Note that Cisco cannot directly support any 
third-party terminal applications.  VM Maestro will call the terminal 
application as you specify, but Cisco does not guarantee whether any particular 
will work in conjunction with VM Maestro.  

To help the VIRL PE users, we have gathered scripts and other contributions from 
the user community for launching various terminal applications from VM Maestro. 
These instructions are provided "as is", without warranty of any kind.  We rely 
on our users to help us keep the instructions for various terminal applications 
up-to-date.  We would be happy for your feedback and contributions.  If you have 
a suggestion for how to fix or improve the instructions for a particular 
terminal application, or if you know how to integrate a terminal application 
that is not listed here with VM Maestro, please submit a [pull request](https://help.github.com/articles/about-pull-requests/) or start a new 
discussion on the [VIRL CLN Community Forum](https://learningnetwork.cisco.com/groups/virl).
