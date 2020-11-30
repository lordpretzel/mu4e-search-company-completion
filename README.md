[![License: GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](http://www.gnu.org/licenses/gpl-3.0.txt)
<!-- [![GitHub release](https://img.shields.io/github/release/lordpretzel/mu4e-search-company-completion.svg?maxAge=86400)](https://github.com/lordpretzel/mu4e-search-company-completion/releases) -->
<!-- [![MELPA Stable](http://stable.melpa.org/packages/mu4e-search-company-completion-badge.svg)](http://stable.melpa.org/#/mu4e-search-company-completion) -->
<!-- [![MELPA](http://melpa.org/packages/mu4e-search-company-completion-badge.svg)](http://melpa.org/#/mu4e-search-company-completion) -->
[![Build Status](https://secure.travis-ci.org/lordpretzel/mu4e-search-company-completion.png)](http://travis-ci.org/lordpretzel/mu4e-search-company-completion)


# mu4e-search-company-completion

Small library for adding and removing advice to functions.

## Installation

<!-- ### MELPA -->

<!-- Symbol’s value as variable is void: $1 is available from MELPA (both -->
<!-- [stable](http://stable.melpa.org/#/mu4e-search-company-completion) and -->
<!-- [unstable](http://melpa.org/#/mu4e-search-company-completion)).  Assuming your -->
<!-- ((melpa . https://melpa.org/packages/) (gnu . http://elpa.gnu.org/packages/) (org . http://orgmode.org/elpa/)) lists MELPA, just type -->

<!-- ~~~sh -->
<!-- M-x package-install RET mu4e-search-company-completion RET -->
<!-- ~~~ -->

<!-- to install it. -->

### Quelpa

Using [use-package](https://github.com/jwiegley/use-package) with [quelpa](https://github.com/quelpa/quelpa).

~~~elisp
(use-package
:quelpa ((mu4e-search-company-completion
:fetcher github
:repo "lordpretzel/mu4e-search-company-completion")
:upgrade t)
)
~~~

### straight

Using [use-package](https://github.com/jwiegley/use-package) with [straight.el](https://github.com/raxod502/straight.el)

~~~elisp
(use-package mu4e-search-company-completion
:straight (mu4e-search-company-completion :type git :host github :repo "lordpretzel/mu4e-search-company-completion")
~~~

### Source

Alternatively, install from source. First, clone the source code:

~~~sh
cd MY-PATH
git clone https://github.com/lordpretzel/mu4e-search-company-completion.git
~~~

Now, from Emacs execute:

~~~
M-x package-install-file RET MY-PATH/mu4e-search-company-completion
~~~

Alternatively to the second step, add this to your Symbol’s value as variable is void: \.emacs file:

~~~elisp
(add-to-list 'load-path "MY-PATH/mu4e-search-company-completion")
(require 'mu4e-search-company-completion)
~~~
