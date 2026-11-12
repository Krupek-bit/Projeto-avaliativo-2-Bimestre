<div class="row g-3">
  <div class="col-12 col-md-6">
    <label class="form-label">Veículo</label>
    <select name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach($veiculos as $v)
        <option value="{{ $v->id_veiculo }}" @selected(old('id_veiculo', $manutencao->id_veiculo ?? '') == $v->id_veiculo)>
          {{ $v->placa }} - {{ $v->modelo }}
        </option>
      @endforeach
    </select>
    @error('id_veiculo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Tipo</label>
    <input type="text" name="tipo_manutencao" maxlength="50" value="{{ old('tipo_manutencao', $manutencao->tipo_manutencao ?? '') }}"
           class="form-control @error('tipo_manutencao') is-invalid @enderror" placeholder="Preventiva, corretiva...">
    @error('tipo_manutencao') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12">
    <label class="form-label">Descrição</label>
    <input type="text" name="descricao" maxlength="255" value="{{ old('descricao', $manutencao->descricao ?? '') }}"
           class="form-control @error('descricao') is-invalid @enderror">
    @error('descricao') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-md-6">
    <label class="form-label">Oficina</label>
    <input type="text" name="oficina" maxlength="100" value="{{ old('oficina', $manutencao->oficina ?? '') }}"
           class="form-control @error('oficina') is-invalid @enderror">
    @error('oficina') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Valor</label>
    <input type="number" step="0.01" name="valor" value="{{ old('valor', $manutencao->valor ?? '') }}"
           class="form-control @error('valor') is-invalid @enderror">
    @error('valor') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Quilometragem</label>
    <input type="number" name="quilometragem" value="{{ old('quilometragem', $manutencao->quilometragem ?? '') }}"
           class="form-control @error('quilometragem') is-invalid @enderror">
    @error('quilometragem') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('manutencoes.index') }}" class="btn btn-secondary">Cancelar</a>
</div>
