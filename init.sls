micro:
  pkg.installed

bash-completion:
  pkg.installed

webext-ublock-origin-firefox:
  pkg.installed

keepassxc:
  pkg.installed

git:
  pkg.installed

/home/Passwords.kdbx:
  file.managed:
    - source: "salt://musthavesoftware/Passwords.kdbx"
