(setq lexical-binding t)

(message "Start loading init.el")

(defvar host-dir "~/.emacs.d/host/")
(if (file-exists-p host-dir)
    (progn
      (message "Start loading host init")
      (add-to-list 'load-path host-dir)
      (require 'init-host)
      (message "Finish loading host init"))
  (warn "Host file not found"))

;; customize file
(defvar var-dir (concat user-emacs-directory "var/"))
(make-directory var-dir :parents)
(setq custom-file (concat var-dir "custom.el"))

;; no temporary files
(defvar backup-dir (concat var-dir "backup"))
(defvar auto-save-dir (concat var-dir "auto-save/"))
(make-directory backup-dir :parents)
(make-directory auto-save-dir :parents)
(setq backup-directory-alist
      `(("." . ,backup-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,auto-save-dir t)))
(setq create-lockfiles nil)

;; no menu bar
(menu-bar-mode -1)
;; no tool bar
(tool-bar-mode -1)

;; default font
(set-face-attribute 'default nil
                    :family "Iosevka Yinfeng"
                    :height 100
                    :weight 'normal
                    :width 'normal)

;; no tabs
(setq-default indent-tabs-mode nil)

;; windmove
(windmove-default-keybindings)

;; split thresholds
(setq split-height-threshold 120
      split-width-threshold 120)

;; quoted char radix
(setq read-quoted-char-radix 16)

;; open init.el command
(defun open-dotfiles ()
  "Open dotfiles"
  (find-file "~/Source/dotfiles"))
(defun open-init-el ()
  "Open init.el file"
  (interactive)
  (find-file "~/Source/dotfiles/users/profiles/emacs/init.el"))
(defun nixos-rebuild-switch ()
  "NixOS rebuild"
  (interactive)
  (async-shell-command "sudo nixos-rebuild switch"))
(defun restart-emacs-daemon ()
  "Restart emacs"
  (interactive)
  (async-shell-command "systemctl --user restart emacs"))

;; packages
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")))
(require 'package)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-demand t)

(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window)))

(use-package avy
  :ensure t
  :config
  (global-set-key (kbd "C-:") 'avy-goto-char-timer))

(use-package cdlatex
  :ensure t
  :config
  (use-package texmathp
    :ensure auctex)
  :hook ((org-mode . turn-on-org-cdlatex)))

(use-package company
  :ensure t
  :hook ((after-init . global-company-mode)))

(use-package counsel
  :ensure t
  :delight
  :config
  (counsel-mode)
  (use-package ivy
    :ensure t
    :delight
    :config
    (ivy-mode))
  (use-package swiper
    :ensure t
    :config
    (global-set-key (kbd "C-s") 'swiper-isearch)))

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode))

(use-package delight
  :ensure t)

(use-package direnv
  :ensure t
  :config
  (direnv-mode))

(use-package eldoc
  :ensure t)

(use-package expand-region
  :ensure t
  :config
  (global-set-key (kbd "C-=") 'er/expand-region))

(use-package fish-mode
  :ensure t)

(use-package flycheck
  :ensure t)

(use-package flycheck-projectile
  :ensure t)

(use-package flyspell
  :ensure nil ; builtin
  :hook ((org-mode . flyspell-mode)
         (TeX-mode . flyspell-mode)))

(use-package json-mode
  :ensure t)

(use-package ligature
  :config
  (ligature-set-ligatures '(prog-mode)
                          ;; lists of default ligations of Iosevka
                          '("<--" "<---" "<<-" "<-" "->" "->>" "-->" "--->" "<->" "<-->" "<--->" "<---->" "<!--"
                            "<==" "<===" "<<=" "<=" "=>" "=>>" "==>" ">=" ">>=" "<=>" "<==>" "<===>" "<====>" "<!---"
                            "<~~" "<~" "~>" "~~>" "::" ":::" "==" "!=" "===" "!==" ":>"
                            ":=" ":-" ":+" "<*" "<*>" "*>" "<|" "<|>" "|>" "+:" "-:" "=:" "<***>" "++" "+++"))
  (global-ligature-mode t))

(use-package lsp-haskell
  :ensure t)

(use-package lsp-mode
  :ensure t
  :hook ((lsp-mode . (lambda ()
                       (let ((lsp-keymap-prefix "C-c l"))
                         (lsp-enable-which-key-integration))))
         (haskell-mode . lsp)
         (haskell-literate-mode . lsp)
         (c-mode . lsp)
         (c++-mode . lsp)
         (rust-mode . lsp))
  :custom
  (lsp-rust-server 'rust-analyzer)
  (lsp-rust-analyzer-proc-macro-enable t)
  (lsp-rust-analyzer-rustc-source "discover")
  (lsp-rust-analyzer-experimental-proc-attr-macros t)
  :config
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map))

(use-package idris-mode
  :ensure t)

(use-package lsp-ui
  :ensure t)

(use-package lua-mode
  :ensure t)

(use-package magit
  :ensure t)

(use-package markdown-mode
  :ensure t)

(use-package nyan-mode
  :ensure t
  :custom
  (nyan-animate-nyancat t)
  (nyan-bar-length 16)
  (nyan-wavy-trail t)
  :config
  (nyan-mode))

(use-package neotree
  :ensure t
  :custom
  (neo-smart-open t)
  :bind
  (("C-c t s" . neotree-show)
   ("C-c t t" . neotree-toggle)))

(use-package nix-mode
  :ensure t)

(use-package ob-rust
  :ensure t)

(use-package org
  :ensure t
  :custom
  (org-directory "/var/lib/syncthing/Main/orgs")
  (org-startup-indented t)
  ;; done with time information
  (org-log-done 'time)
  :bind (("C-c o l" . org-store-link)
         ("C-c o a" . org-agenda)
         ("C-c o c" . org-capture)))

(use-package org-agenda
  :ensure org
  :custom
  (org-agenda-file-regexp "\\`[^.].*\\.org\\'\\|[0-9-]+")
  :config
  (add-to-list 'org-agenda-files "/var/lib/syncthing/Main/orgs/tasks"))

(use-package org-bullets
  :ensure t
  :custom
  (org-bullets-bullet-list
   '("●"
     "○"
     "✿"
     "❀"
     "◆"
     "◇"))
  :hook (org-mode . (lambda () (org-bullets-mode 1))))

(use-package org-journal
  :ensure t
  :init
  (setq org-journal-prefix-key "C-c j ")
  :custom
  (org-journal-dir "/var/lib/syncthing/Main/orgs/journal")
  (org-journal-file-format "%Y-%m-%d")
  :config
  ;; include journal in agenda
  (add-to-list 'org-agenda-files "/var/lib/syncthing/Main/orgs/journal"))

(use-package org-roam
  :ensure t
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "/var/lib/syncthing/Main/orgs/notes"))
  (org-roam-completion-everywhere t)
  (org-roam-capture-templates
   (let ((file-format "%<%Y%m%d%H%M%S>-${slug}.org"))
     `(("d" "default" plain "%?"
        :target (file+head ,file-format "#+title: ${title}")
        :unnarrowed t)
       ("p" "paper" plain (file "~/.emacs.d/var/orgs/templates/paper.org")
        :target (file+head ,file-format "#+title: ${title}\n#+filetags: Paper")
        :unnarrowed t))))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies: use org-journal instead
         ;; ("C-c n j" . org-roam-dailies-capture-today)
         :map org-mode-map
         ("C-M-i"   . completion-at-point))
  :config
  ;; db auto sync
  (org-roam-db-autosync-mode))

(defun sync-orgs ()
  "Sync orgs notes"
  (interactive)
  (let ((default-directory org-directory))
    (async-shell-command "nix-shell --command update-all")))

(use-package paredit
  :ensure t)

(use-package proof-general
  :ensure t
  :custom
  (proof-three-window-enable t)
  (proof-three-window-mode-policy 'hybrid))

(use-package pdf-tools
  :ensure t
  :custom
  (doc-view-resolution 300)
  (pdf-view-use-scaling t)
  :config
  (pdf-tools-install))

(use-package projectile
  :ensure t
  :delight
  :custom
  (projectile-switch-project-action 'neotree-projectile-action)
  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (projectile-mode +1))

(use-package pyim
  :ensure t
  :delight pyim-isearch-mode
  :custom
  (default-input-method "pyim")
  (pyim-page-tooltip '(popup minibuffer))
  (pyim-default-scheme 'quanpin)
  (pyim-page-length 5)
  (pyim-english-input-switch-functions
   '(pyim-probe-dynamic-english
     pyim-probe-isearch-mode
     pyim-probe-program-mode
     pyim-probe-org-structure-template))
  (pyim-punctuation-half-width-functions
   '(pyim-probe-punctuation-line-beginning
     pyim-probe-punctuation-after-punctuation))
  (pyim-dicts
   `((:name "Greatdict" :file ,(concat var-dir "pyim/greatdict.pyim.gz"))))
  :config
  (pyim-isearch-mode 1)
  (define-key pyim-mode-map "." 'pyim-page-next-page)
  (define-key pyim-mode-map "," 'pyim-page-previous-page)
  :bind
  (("C-|" . pyim-convert-string-at-point)))

(use-package racket-mode
  :ensure t)

(use-package rainbow-delimiters
  :ensure t)

(use-package rg
  :ensure t)

(use-package rust-mode
  :ensure t)

(use-package scribble-mode
  :ensure t)

(use-package sudo-edit
  :ensure t)

(use-package swift-mode
  :ensure t)

(use-package telega
  :ensure t)

(use-package tex
  :ensure auctex
  :custom
  ;; use default value
  ;; (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-source-correlate-start-server t)
  (TeX-source-correlate-mode t)
  :config
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

(use-package undo-tree
  :ensure t
  :delight
  :custom
  (undo-tree-history-directory-alist `(("." . ,(concat var-dir "undo-tree"))))
  :config
  (global-undo-tree-mode))

(use-package webkit
  :config
  (require 'webkit-ace))

(use-package which-key
  :ensure t
  :delight
  :config
  (which-key-mode))

(use-package yaml-mode
  :ensure t)

(defun load-agda-mode ()
  "Open init.el file"
  (interactive)
  (load-file (let ((coding-system-for-read 'utf-8))
               (shell-command-to-string "agda-mode locate"))))

(message "Finish loading init.el")
