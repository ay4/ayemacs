;; Hide the initial frame until the theme has loaded to avoid a white flash
(push '(visibility . nil) initial-frame-alist)

;; Disable package.el — straight.el handles everything
(setq package-enable-startup nil)
