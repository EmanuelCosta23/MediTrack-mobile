package com.meditrackapi.Meditrack.service;

import com.meditrackapi.Meditrack.dao.Repositories.*;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.*;
import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.ListaPostosResponse;
import com.meditrackapi.Meditrack.domain.Entities.HistoricoEstoque;
import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import com.meditrackapi.Meditrack.domain.Entities.auxiliar.UsuarioMedicamento;
import com.meditrackapi.Meditrack.domain.Interfaces.IMedicamentoService;
import com.opencsv.bean.CsvToBean;
import com.opencsv.bean.CsvToBeanBuilder;
import com.opencsv.bean.HeaderColumnNameMappingStrategy;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class MedicamentoService implements IMedicamentoService {

    private final UsuarioMedicamentoRepository _userMedRepo;
    private final MedicamentoPostoRepository _medPostoRepo;
    private final MedicamentoRepository _medicamentoRepo;
    private final PostoRepository _postoRepo;
    private final UsuarioRepository _userRepo;
    private final HistoricoEstoqueRepository _historicoEstoqueRepo;
    public MedicamentoService(MedicamentoRepository medicamentoRepository,
                              PostoRepository postoRepository,
                              MedicamentoPostoRepository medicamentoPostoRepository,
                              UsuarioRepository usuarioRepository,
                              UsuarioMedicamentoRepository usuarioMedicamentoRepository,
                              HistoricoEstoqueRepository historicoEstoqueRepository
                              ){
        _medicamentoRepo = medicamentoRepository;
        _postoRepo = postoRepository;
        _medPostoRepo = medicamentoPostoRepository;
        _userRepo = usuarioRepository;
        _userMedRepo = usuarioMedicamentoRepository;
        _historicoEstoqueRepo = historicoEstoqueRepository;
    }

    @Override
    public List<ListaMedsResponse> SearchByName(String nome){
        return _medicamentoRepo.findByName(nome);
    }

    @Override
    public MedicamentoResponse SearchById(String medicamentoId){
        Medicamento medicamento = _medicamentoRepo.findById(medicamentoId)
                .orElseThrow(() -> new IllegalArgumentException("Medicamento não encontrado."));

        List<ListaPostosResponse> postos = _postoRepo.findPostosByMedicamentoId(medicamentoId);

        return new MedicamentoResponse(
                medicamento.getCodigo(),
                medicamento.getLote(),
                medicamento.getProduto(),
                medicamento.getTipo(),
                medicamento.getVencimento(),
                medicamento.isNecessitaReceita(),
                postos
            );
    }

    public Integer InserirCargaMedicamentos(MultipartFile file) throws IOException {
        Set<Medicamento> medicamentos = parseCsv(file);
        _medicamentoRepo.saveAll(medicamentos);
        return medicamentos.size();
    }

    public Integer AtualizarEstoque(MultipartFile file) throws IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _userRepo.findByEmail(loggedInUserEmail);

        Posto posto = usuarioLogado.getPosto();
        atualizarHistorico(posto, usuarioLogado);

        Set<UpdateEstoqueCsvReprensentation> medicamentos = parseEstoqueCsv(file);
        int updatesCount = 0;
        for (UpdateEstoqueCsvReprensentation csvLine : medicamentos) {
            Optional<Medicamento> medicamentoOpt = _medicamentoRepo.findByCodigo(csvLine.get_codigo());
            if (medicamentoOpt.isPresent()) {
                Medicamento medicamento = medicamentoOpt.get();
                updatesCount += _medPostoRepo.updateQuantidadeEstoque(posto.getId(), medicamento.getId(), csvLine.get_quantidade());
            }
        }
        return updatesCount;
    }

    public List<MedicamentoCard> listarMedicamentosPorPosto(){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _userRepo.findByEmail(loggedInUserEmail);
        String postoId = usuarioLogado.getPosto().getId();
        return _medicamentoRepo.findAllByPostoId(postoId);
    }

    public void favoritarMedicamento(String medicamentoId){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _userRepo.findByEmail(loggedInUserEmail);
        Medicamento medicamento = _medicamentoRepo.findById(medicamentoId)
                .orElseThrow(()-> new IllegalArgumentException("Não foi possível encontrar o medicamento."));
        UsuarioMedicamento usuarioMed = new UsuarioMedicamento(usuarioLogado, medicamento);
        _userMedRepo.save(usuarioMed);
    }

    public List<MedicamentoCard> listarMedicamentosFavoritos(){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _userRepo.findByEmail(loggedInUserEmail);
        return _userMedRepo.findMedicamentosByUsuarioId(usuarioLogado.getId());
    }

    private void atualizarHistorico(Posto posto, Usuario funcionario){
        HistoricoEstoque novoRegistro = new HistoricoEstoque(posto, funcionario);
        _historicoEstoqueRepo.save(novoRegistro);
    }

    private Set<Medicamento> parseCsv(MultipartFile file) throws IOException {
        try(Reader reader = new BufferedReader(new InputStreamReader(file.getInputStream()))) {
            HeaderColumnNameMappingStrategy<MedicamentoCsvRepresentation> strategy =
                    new HeaderColumnNameMappingStrategy<>();
            strategy.setType(MedicamentoCsvRepresentation.class);
            CsvToBean<MedicamentoCsvRepresentation> csvToBean =
                    new CsvToBeanBuilder<MedicamentoCsvRepresentation>(reader)
                            .withMappingStrategy(strategy)
                            .withIgnoreEmptyLine(true)
                            .withIgnoreLeadingWhiteSpace(true)
                            .build();
            return csvToBean.parse()
                    .stream()
                    .map(csvLine -> Medicamento.builder()
                            .codigo(csvLine.get_codigo())
                            .produto(csvLine.get_produto())
                            .lote(csvLine.get_lote())
                            .necessitaReceita(csvLine.is_necessita_receita())
                            .vencimento(csvLine.get_vencimento())
                            .build()
                    ).collect(Collectors.toSet());
        }
    }

    private Set<UpdateEstoqueCsvReprensentation> parseEstoqueCsv(MultipartFile file) throws IOException {
        try (Reader reader = new BufferedReader(new InputStreamReader(file.getInputStream()))) {
            return new HashSet<>(new CsvToBeanBuilder<UpdateEstoqueCsvReprensentation>(reader)
                    .withType(UpdateEstoqueCsvReprensentation.class)
                    .withIgnoreLeadingWhiteSpace(true)
                    .build()
                    .parse());
        }
    }
}
