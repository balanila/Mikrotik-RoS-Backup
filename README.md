
   * [What is this?]

* This script can help you to backup RoS config to .rsc file.

* Automaticly send to telegram information about failed backups. 

* Optional you can store files in the git repo to control versions.

   * [Requirements]

Connections to RoS take with rsa keys and specified user.
In the script you have to specify variables:
* Username from RoS (var: username)
* Key file name (var: keyfile)
* Working dir (var: wf)
* backup folder for rsc files (var: bf)
* Folder for general logs (var: logs)
* git dir (var: gitdir)
* Filename with ip addresses (var: list)
* Telegram bot api key (var: tbi)
* Telegram chat id (var: tci)
* Client name (if need it) (var: client)

   * [How to use it]
* Change variables to indicate yours dirs
* Generate RSA keypair and install public key on each RoS
* Fill node_list with ip addesses. Attention: empty space is not allowed
* set user name

