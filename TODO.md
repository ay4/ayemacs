# TODO

- [ ] Get Telegram API credentials for `telega`: log in at https://my.telegram.org with your phone number, go to "API development tools," create an app (any name/platform), and note the `api_id` and `api_hash`. Then add to `config/apps.el`, right before the `(use-package telega ...)` block:

  ```elisp
  (setq telega-app
        '(:api-id 12345678 :api-hash "your-hash-here"))
  ```
