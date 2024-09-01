<a id="readme-top"></a>


------

#### Setting up (manual)

Its a bash script, for god's sake,
`git clone` the repo and `chmod +x` the script.

```bash
git clone https://github.com/auth-xyz/nixpm
cd nixpm
chmod +x ./nixpm.sh
```
--------

#### Setting up (home-manager)

This is the fun version of the setup.
No need for git cloning this repo. Instead, you'll edit the `flake.nix` file on your home-manager

```nix
{
         inputs = {
           nixpm.url = "github:auth-xyz/nixpm";
         };

         outputs = { nixpkgs, home-manager, nixpm, ... }:
         let
            the two things here
         in {
            homeConfigurations thing {
                  inherit pkgs;
                  modules = [ ./home.nix ];
                  extraSpecialArgs = { inherit nixpm; };
            }
         };
}
```

Basically, add the `nixpm.url` to inputs, add `nixpm` to outputs, and the extraSpecialArgs.
now moving to home.nix:

Almost the same thing, but in the first line 
```nix
#{ config,pkgs,...} # you'll add nixpm, so
{ config, pkgs, nixpm, ... }:
{
 # ... the rest of your home
 home.packages = with pkgs; [ nixpm.packages.${pkgs.stdenv.hostPlatform.system}.nixpkg ];
}
```
And then, rebuild your home-manager. And you have nixpm installed.

--------

#### Usage 

```bash
./nixpm.sh packages here separated by spaces # this will go to .config/home-manager/
sudo ./nixpm.sh same thing as above # but the packages will be sent to /etc/nixos/


# ^-- basic usage 

nixpm.sh -r/--remove <packages>
         -a/--add (default) <packages>
         -h/--help 

```

------

#### Contributing

Feel free to contribute in any way you'd like, just make a PR.
If you have any questions on how to use the source code/edit the code dm me on Discord <actually.auth>




