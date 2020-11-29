;;; magit-arcanist.el --- Magit popup for Arcanist interaction -*- lexical-binding:t ; -*-

;;; Copyright © 2018-2018 Jonathan Jin <jjin082693@gmail.com>

;; Author: Jonathan Jin <jjin082693@gmail.com>
;; URL: https://github.com/jinnovation/helm-exec
;; Keywords: magit, arcanist, vc, source-control
;; Version: 0.1.0

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:

;; This package provides integration for Magit to natively interact with
;; Arcanist (https://secure.phabricator.com/book/phabricator/article/arcanist),
;; the CLI for Phabricator (https://phacility.com).

;;; Code:

(require 'magit)
(require 'with-editor)
(require 'magit-popup)

(defcustom magit-arcanist-key (kbd "@")
  "Key to invoke the magit-arcanist popup within Magit.

This needs to be set before the call to `magit-arcanist-enable'."
  :type 'string)

(defcustom magit-arcanist-arc-executable (executable-find "arc")
  "Path to the `arc' executable.

`magit-arcanist-enable' will fail if this path does not exist."
  :type 'string)

(defcustom magit-arcanist-default-arguments "--no-ansi"
  "Arguments passed to `arc' executable by default.

Defaults to `--no-ansi' to disable
color output which does not get interpreted by default subprocess
output."
  :type 'string)

(defun magit-arcanist--run-arc-cmd (cmd &rest args)
  "Run arc CMD with default arguments and provided ARGS."
  (let ((cmd-with-flags (append (list magit-arcanist-default-arguments cmd)
                                (seq-filter #'identity args))))
    (with-editor "GIT_EDITOR"
      (apply #'magit-start-process magit-arcanist-arc-executable nil cmd-with-flags))))

;; arc feature
(defun magit-arcanist-feature (name)
  "Run the following command: arc feature NAME."
  (interactive "sFeature branch name: ")
  (magit-arcanist--run-arc-cmd "feature" name))

;; clean branches
(defun magit-arcanist--do-clean-branches (&optional flags)
  "Remove all branches associated with landed diffs using FLAGS."
  (interactive (magit-arcanist-clean-branches-arguments))
  (magit-arcanist--run-arc-cmd "clean-branches" flags))

(magit-define-popup magit-arcanist-clean-branches-popup
  "Popup console for `clean-branches' command."
  :switches '((?d "Delete branches associated with abandoned diffs" "--delete-abandoned")
              (?p "Dry run" "--dry-run"))
  :actions '((?c "Clean branches" magit-arcanist--do-clean-branches)))

(magit-define-popup magit-arcanist-popup
  "Popup console for Arcanist commands."
  :actions '((?d "Diff" magit-arcanist-diff-popup)
             (?f "Feature" magit-arcanist-feature)
             (?l "Land" magit-arcanist-land-popup)
             (?c "Clean branches" magit-arcanist-clean-branches-popup))
  :max-action-columns 2)

;; arc land
(defun magit-arcanist--do-land (&optional flags)
  "Run `arc land' using FLAGS, e.g. \"--preview\"."
  (interactive (magit-arcanist-land-arguments))
  (magit-arcanist--run-arc-cmd "land" flags))

(magit-define-popup magit-arcanist-land-popup
  "Popup console for Arcanist land commands."
  :switches '((?p "Preview" "--preview")
              (?k "Keep branch" "--keep-branch"))
  :actions '((?l "Land" magit-arcanist--do-land)))

;; arc diff
(defun magit-arcanist--do-diff (&optional flags)
  "Run `arc diff' using FLAGS, e.g. \"--nolint\"."
  (interactive (magit-arcanist-diff-arguments))
  (magit-arcanist--run-arc-cmd "diff" flags))

(magit-define-popup magit-arcanist-diff-popup
  "Popup console for Arcanist diff commands."
  :switches '((?l "No lint" "--nolint")
              (?u "No unit tests" "--nounit")
              (?c "No coverage info" "--no-coverage")
              (?a "Amend autofixes" "--amend-autofixes")
              (?d "Create draft" "--draft")
              (?b "browse" "--browse"))
  :actions '((?d "Diff" magit-arcanist--do-diff)))


(defun magit-arcanist--can-enable-p ()
  "Returns nil if preconditions for magit-arcanist initialization
are not met."
  (and (executable-find magit-arcanist-arc-executable)))

(defun magit-arcanist-enable ()
  "Enables magit-arcanist for use by binding `magit-arcanist-pop' to
`magit-arcanist-key' within `magit-mode-map'."
  (interactive)
  (progn
    (when (not (magit-arcanist--can-enable-p))
        (error "Arcanist executable does not exist: %s"
               magit-arcanist-arc-executable))

    (define-key magit-mode-map magit-arcanist-key 'magit-arcanist-popup)))

(provide 'magit-arcanist)

;;; magit-arcanist.el ends here
