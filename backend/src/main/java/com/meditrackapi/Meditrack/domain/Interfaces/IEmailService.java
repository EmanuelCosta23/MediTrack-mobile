package com.meditrackapi.Meditrack.domain.Interfaces;

public interface IEmailService {
    void SendMail(String receiver, String subject, String body);
}
