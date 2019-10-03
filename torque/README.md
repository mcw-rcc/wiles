# Wiles Cluster Torque Config

Wesla configuration scripts and items.

# Enable security
add following to /etc/pam.d/{login,sshd}:
account required pam_access.so
