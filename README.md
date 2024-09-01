<a id="readme-top"></a>


------

#### Setting up

Its a bash script, for god's sake,
`git clone` the repo and `chmod +x` the script.

```bash
git clone https://github.com/auth-xyz/nixpm
cd nixpm
chmod +x ./nixpm.sh
```

--------

#### Usage 

```bash
./nixpm.sh packages here separated by spaces # this will go to .config/home-manager/
sudo ./nixpm.sh same thing as above # but the packages will be sent to /etc/nixos/

```

After the packages.nix file is generated, you do need to import on either `configuration.nix` or `home.nix`
you know how that goes,
```nix
imports = [
    ./packages.nix
  ];
```

------

#### Contributing

Feel free to contribute in any way you'd like, just make a PR.
If you have any questions on how to use the source code/edit the code dm me on Discord <actually.auth>




