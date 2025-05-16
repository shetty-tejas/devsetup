# DevSetup

A language/environment agnostic tool for package management that works in any POSIX compliant shell.

## Features

- Cross-platform compatibility with any POSIX compliant shell
- Simple and straightforward package management
- Customizable, and maintainable configuration
- Easy installation process

## Installation

Install 'devsetup' with a single command:

```sh
curl https://raw.githubusercontent.com/shetty-tejas/devsetup/refs/heads/master/install.sh | sh
```

After it's installed, you need to initialize the config file:

```sh
devsetup init-config
```

You should be finding the config file in `$HOME/.config/devsetup.json`.
###### NOTE: You can also set a custom directory for storing your config file by setting DEVSETUP_CONFIG_FOLDER environment variable.

## Usage

After installation, you can manage your development environment and packages using the `devsetup` command.

1. You can install the packages for a particular tool by calling `devsetup install {tool}`.

```sh
devsetup install nodejs # Please note that, the package installation command should be configured in 'commands.nodejs.install', and tools should be configured under 'tools.nodejs' as an array.
```

2. You can update the devsetup installation by calling `devsetup update-self`.

For more information, see the documentation in the [source code](https://github.com/shetty-tejas/devsetup).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DevSetup project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/shetty-tejas/devsetup/blob/main/CODE_OF_CONDUCT.md).
