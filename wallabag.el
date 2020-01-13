;;; wallabag.el --- An Emacs Wallabag client         -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Jeremy Dormitzer

;; Author: Jeremy Dormitzer <jeremy.dormitzer@gmail.com>
;; Keywords: tools, multimedia

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is an Emacs client for the Wallabag read-later service.

;;; Code:

(defun wallabag-url (base-url path)
  (format "%s/%s"
    (s-chop-suffix "/" base-url)
    (s-chop-prefix "/" path)))

(defun wallabag-get-api-token (base-url client-id client-secret username password)
  "Obtains a new Wallabag API access token."
  (request
    (wallabag-url base-url "oauth/v2/token")
    :type "POST"
    :parser 'json-read
    :data `(("grant_type" . "password")
            ("client_id" . ,client-id)
            ("client_secret" . ,client-secret)
            ("username" . ,username)
            ("password" . ,password))))

(provide 'wallabag)
;;; wallabag.el ends here
