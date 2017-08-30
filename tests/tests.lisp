;;;;  cl-esmtp-client
;;;;
;;;;  Copyright (C) 2017 Thomas Bakketun <thomas.bakketun@copyleft.no>
;;;;
;;;;  This library is free software: you can redistribute it and/or modify
;;;;  it under the terms of the GNU Lesser General Public License as published
;;;;  by the Free Software Foundation, either version 3 of the License, or
;;;;  (at your option) any later version.
;;;;
;;;;  This library is distributed in the hope that it will be useful,
;;;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;  GNU General Public License for more details.
;;;;
;;;;  You should have received a copy of the GNU General Public License
;;;;  along with this library.  If not, see <http://www.gnu.org/licenses/>.

(in-package #:cl-esmtp-client-tests)


(defun talk-to-smtp-server (&key settings mail-from rcpt-to data)
  (esmtp:with-session settings
    (esmtp:mail-from mail-from)
    (esmtp:rcpt-to rcpt-to)
    (when data
      (esmtp:data-start)
      (esmtp:data-bytes data)
      (esmtp:data-end))))


(defun talk-to-test.smtp.org ()
  (talk-to-smtp-server :settings '(:host "test.smtp.org"
                                   :cl+ssl-options (:verify nil)
                                   :credentials ("user16" "pass16"))
                       :mail-from ""
                       :rcpt-to "bit-bucket"
                       :data (flex:string-to-octets
"From: Me <me@example.com>
To: You <you@example.com>
Subject: Test

Hello World.")))


(defvar *mailtrap.io-credentials*
  ;; All mail sent using these credentials are discarded by mailtrap.io.
  ;; Exposing them is unlikely to allow for any misuse.
  (list "479a48b137b928"
        (lambda () "3d7550496f7a14")))

(defun talk-to-mailtrap.io ()
  (esmtp:with-session (list :host "smtp.mailtrap.io"
                             :port 2525
                             :credentials *mailtrap.io-credentials*
                             :trace *trace-output*)
    (esmtp:mail-from "me@example.com")
    (esmtp:rcpt-to "you@example.com")
    (esmtp:data '("From: Me <me@example.com>"
                   "To: You <you@example.com>"
                   "Subject: Test"
                   ""
                   "Hello World."))))


(defun talk-to-gmail.com ()
  (esmtp:with-session (list :host "smtp.gmail.com"
                            :trace *trace-output*)
    (esmtp:noop)
    (esmtp:rset)
    (format t "~&Verify reply: ~A" (esmtp:send-command 252 "VRFY postmaster"))
    (format t "~&Initial greeting: ~A" (esmtp:greeting))
    (format t "~&Hello greeting: ~A" (esmtp:hello-greeting))
    (format t "~&Supported extentions: ~S" (esmtp:extensions))
    (format t "~&Maximium message size: ~A" (esmtp:max-size))
    (handler-case (esmtp:mail-from "me@example.com")
      (esmtp:permanent-error (e)
        (format t "~&======~&Got error as expected:~&~A~&======" e)))))


;; python -m smtpd -n -c DebuggingServer localhost:2525
(defun talk-to-local-python ()
  (esmtp:with-session '(:host "localhost"
                         :port 2525
                         :trace t)
    (esmtp:mail-from "me@example.com")
    (esmtp:rcpt-to "you@example.com")
    (esmtp:data '("From: Me <me@example.com>"
                   "To: You <you@example.com>"
                   "Subject: Test"
                   ""
                   "Hello World."))))


(defun run ()
  (talk-to-test.smtp.org)
  (talk-to-mailtrap.io)
  (talk-to-gmail.com))


(defun travis-run ()
  (talk-to-mailtrap.io)
  (talk-to-gmail.com))
