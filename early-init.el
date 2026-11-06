;;; early-init.el --- -*- lexical-binding: t; -*-
;; Hide the initial frame until the theme has loaded to avoid a white flash
(push '(visibility . nil) initial-frame-alist)

;; Transparent title bar (macOS): native chrome hidden, traffic-light buttons
;; appear inset over the frame content like Sublime Text.
;; ns-appearance (dark/light) is updated at runtime by ay-setup-frame-border.
(when (eq system-type 'darwin)
  (push '(ns-transparent-titlebar . t) default-frame-alist)
  (push '(ns-transparent-titlebar . t) initial-frame-alist)
  (setq ns-use-proxy-icon nil))

;; Disable package.el — straight.el handles everything
(setq package-enable-startup nil)

;; Background native compilation of third-party packages: compile quietly.
;; Their "function not known to be defined" warnings are harmless and
;; otherwise pop up a *Warnings* buffer the first time a package loads.
(setq native-comp-async-report-warnings-errors 'silent)
