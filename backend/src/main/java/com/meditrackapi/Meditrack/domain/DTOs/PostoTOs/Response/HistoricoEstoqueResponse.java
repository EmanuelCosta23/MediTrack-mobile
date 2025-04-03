package com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response;

import com.fasterxml.jackson.annotation.JsonFormat;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

public interface HistoricoEstoqueResponse {
    String getRegistroId();
    @JsonFormat(pattern = "dd/MM/yyyy HH:mm:ss")
    LocalDateTime getDataUpload();
    String getFuncionarioNome();
}
