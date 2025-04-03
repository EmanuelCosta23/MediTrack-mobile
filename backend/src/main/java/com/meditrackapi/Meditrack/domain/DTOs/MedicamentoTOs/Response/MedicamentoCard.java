package com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response;

import java.util.Date;

public interface MedicamentoCard {
    String getMedicamentoId();
    Integer getCodigoMedicamento();
    String getLoteMedicamento();
    String getNomeMedicamento();
    String getTipoMedicamento();
    Boolean getNecessitaReceita();
    Date getDataVencimento();
    Integer getQuantidadeEstoque();
}
