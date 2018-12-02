----
-- User configuration file for lsyncd.
--
-- Use rsyncssh to sync files
-- This uses ssh so make sure the master is authorized to comunicate to the slave via ssh.
--
settings {
	statusFile = "/tmp/lsyncd.stat",
	statusInterval = 1,
	maxDelays = 1,
}
sync {
  default.rsyncssh,
  source="/home/vikram1/images",
  host="159.203.44.11",
  targetdir="/home/images"
}

