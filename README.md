# ElixirMmo

## Demo

You can play it here: https://elixir-mmo.onrender.com

## Controls

Move your character with WASD and press space for a area attack that kills all enemies adjacent to you

## Development Setup
### Prerequisites
**This project requires [Elixir](https://elixir-lang.org)! If you don't have it installed, refer to [this guide](https://elixir-lang.org/install.html).**

### Setting Up A Local Instance
1. Clone this repo and change into its directory:
```sh
git clone https://github.com/GuimilXD/elixir_mmo
cd elixir_mmo
```
2. Install dependencies with [Mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html):
```sh
mix setup
```
3. (Optional) Run all tests and verify they pass:
```sh
mix test
```
4. Start the server:
```sh
mix phx.server
```
**Done! You can now navigate to http://localhost:4000 and start playing ElixirMmo!**

## Release build

1. Set enviroment variables
```sh
mix phx.gen.secret
REALLY_LONG_SECRET

export SECRET_KEY_BASE=REALLY_LONG_SECRET

export PORT=80
export PHX_HOST="example.com"
```

2. Load dependencies and compile assets
```sh
# Initial setup

mix deps.get --only prod

MIX_ENV=prod mix compile

# Compile assets

MIX_ENV=prod mix assets.deploy
```

3. Run mix.phx.release
```sh
mix phx.gen.release
```

4. Finally run mix.release
```sh
MIX_ENV=prod mix release
```

Your build is now ready to be used
