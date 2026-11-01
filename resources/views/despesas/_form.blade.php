<div class="row g-3">
  <div class="col-12 col-md-6">
    <label class="form-label">Veículo</label>
    <select name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach($veiculos as $v)
        <option value="{{ $v->id_veiculo }}" @selected(old('id_veiculo', $despesa->id_veiculo ?? '') == $v->id_veiculo)>
          {{ $v->placa }} - {{ $v->modelo }}
        </option>
      @endforeach
    </select>
    @error('id_veiculo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Data</label>
    <input type="date" name="data_despesa"
           value="{{ old('data_despesa', isset($despesa) ? \Carbon\Carbon::parse($despesa->data_despesa)->format('Y-m-d') : '') }}"
           class="form-control @error('data_despesa') is-invalid @enderror">
    @error('data_despesa') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Valor</label>
    <input type="number" step="0.01" name="valor" value="{{ old('valor', $despesa->valor ?? '') }}"
           class="form-control @error('valor') is-invalid @enderror">
    @error('valor') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-md-6">
    <label class="form-label">Tipo de despesa</label>
    <input type="text" name="tipo_despesa" maxlength="50" value="{{ old('tipo_despesa', $despesa->tipo_despesa ?? '') }}"
           class="form-control @error('tipo_despesa') is-invalid @enderror" placeholder="Pedágio, multa, seguro...">
    @error('tipo_despesa') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-md-6">
    <label class="form-label">Descrição</label>
    <input type="text" name="descricao" maxlength="255" value="{{ old('descricao', $despesa->descricao ?? '') }}"
           class="form-control @error('descricao') is-invalid @enderror">
    @error('descricao') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('despesas.index') }}" class="btn btn-secondary">Cancelar</a>
</div>