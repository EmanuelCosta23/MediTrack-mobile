package com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response;

import com.opencsv.bean.CsvBindByName;
import lombok.*;

import java.util.Date;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MedicamentoCsvRepresentation {
    @CsvBindByName(column = "codigo")
    private int _codigo;
    @CsvBindByName(column = "lote")
    private String _lote;
    @CsvBindByName(column = "produto")
    private String _produto;
    @CsvBindByName(column = "tipo")
    private String _tipo;
    @CsvBindByName(column = "vencimento")
    private Date _vencimento;
    @CsvBindByName(column = "necessita_receita")
    private boolean _necessita_receita;
}
