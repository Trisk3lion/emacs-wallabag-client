;;; wallabag.el --- An Emacs Wallabag client         -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Jeremy Dormitzer

;; Author: Jeremy Dormitzer <jeremy.dormitzer@gmail.com>
;; Keywords: tools, multimedia
;; Package-Requires: ((request "0.3.2"))

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

;;;; Requirements

(require 's)
(require 'request)

;;;; Customization

(defgroup wallabag nil
  "Customization options for the Emacs Wallabag client")

(defcustom wallabag-base-url nil
  "The base URL of the Wallabag instance"
  :group 'wallabag
  :type '(string))

(defcustom wallabag-client-id nil
  "The client ID of the Wallabag client"
  :group 'wallabag
  :type '(string))

(defcustom wallabag-client-secret nil
  "The client secret of the Wallabag client"
  :group 'wallabag
  :type '(string))

(defcustom wallabag-username nil
  "The username of the Wallabag user"
  :group 'wallabag
  :type '(string))

(defcustom wallabag-password nil
  "The password of the Wallabag user"
  :group 'wallabag
  :type '(string))

(cl-defun wallabag-validate-connection-params ()
  "Validates that all necessary connection parameter
are defined. Raises an error if validation fails."
  (let ((do-validate (lambda (sym)
		       (when (or (not (boundp sym))
				 (not (symbol-value sym)))
			 (error "Unable to connect to Wallabag. Please set %s" sym)))))
    (funcall do-validate 'wallabag-base-url)
    (funcall do-validate 'wallabag-client-id)
    (funcall do-validate 'wallabag-client-secret)
    (funcall do-validate 'wallabag-username)
    (funcall do-validate 'wallabag-password)))

(cl-defun wallabag-url (base-url path)
  (format "%s/%s"
	  (s-chop-suffix "/" base-url)
	  (s-chop-prefix "/" path)))

(cl-defun wallabag-get-auth-data (&optional callback)
  "Obtains a new Wallabag API access token and refresh token."
  (wallabag-validate-connection-params)
  (let ((response (request
		    (wallabag-url wallabag-base-url "oauth/v2/token")
		    :sync (not callback)
		    :complete callback
		    :type "POST"
		    :parser 'json-read
		    :data `(("grant_type" . "password")
			    ("client_id" . ,wallabag-client-id)
			    ("client_secret" . ,wallabag-client-secret)
			    ("username" . ,wallabag-username)
			    ("password" . ,wallabag-password)))))
    (when (not callback) response)))

;; TODO cache access token + reauthenticate when token expires
(cl-defun wallabag-request (endpoint &key method callback form-data parser params)
  "Makes a request to a Wallabag instance"
  (let ((make-request (cl-function
		       (lambda (&key data &allow-other-keys)
			 (let* ((access-token (alist-get 'access_token
							 data))
				(response (request
					    (wallabag-url wallabag-base-url endpoint)
					    :sync (not callback)
					    :type (or method "GET")
					    :headers `(("Authorization" .
							,(format "Bearer %s" access-token)))
					    :data form-data
					    :params params
					    :complete callback
					    :parser (or parser 'json-read))))
			   (when (not callback) response))))))
    (if callback
	(wallabag-get-auth-data make-request)
      (funcall make-request :data (request-response-data
				   (wallabag-get-auth-data))))))

;; TODO handle paging (page size is 30 by default)
;;;###autoload
(cl-defun wallabag-entries (&optional callback)
  "Retrieves the list of Wallabag entries"
  (let ((response (wallabag-request "/api/entries.json"
				    :callback callback)))
    (when (not callback) response)))

;;;###autoload
(cl-defun wallabag-add-entry (url &optional callback)
  "Adds a new Wallabag entry"
  (let ((response (wallabag-request "/api/entries.json"
				    :method "POST"
				    :form-data `(("url" . ,url))
				    :callback callback)))
    (when (not callback) response)))

;;;###autoload
(cl-defun wallabag-delete-entry (id &optional callback)
  "Deletes a Wallabag entry"
  (let ((response (wallabag-request (format "/api/entries/%s.json" id)
				    :method "DELETE"
				    :callback callback)))
    (when (not callback) response)))

(provide 'wallabag)
;;; wallabag.el ends here
