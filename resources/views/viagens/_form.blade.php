<div class="row g-3">
  <div class="col-12 col-md-6">
    <label class="form-label">Veículo</label>
    <select name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach($veiculos as $v)
        <option value="{{ $v->id_veiculo }}" @selected(old('id_veiculo', $viagem->id_veiculo ?? '') == $v->id_veiculo)>
          {{ $v->placa }} - {{ $v->modelo }}
        </option>
      @endforeach
    </select>
    @error('id_veiculo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-md-6">
    <label class="form-label">Motorista</label>
    <select name="id_motorista" class="form-select @error('id_motorista') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach($motoristas as $m)
        <option value="{{ $m->id_motorista }}" @selected(old('id_motorista', $viagem->id_motorista ?? '') == $m->id_motorista)>
          {{ $m->nome }}
        </option>
      @endforeach
    </select>
    @error('id_motorista') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6">
    <label class="form-label">Data de saída</label>
    <input type="datetime-local" name="data_saida"
           value="{{ old('data_saida', isset($viagem) ? $viagem->data_saida?->format('Y-m-d\TH:i') : '') }}"
           class="form-control @error('data_saida') is-invalid @enderror">
    @error('data_saida') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6">
    <label class="form-label">Data de retorno</label>
    <input type="datetime-local" name="data_retorno"
           value="{{ old('data_retorno', isset($viagem) ? $viagem->data_retorno?->format('Y-m-d\TH:i') : '') }}"
           class="form-control @error('data_retorno') is-invalid @enderror">
    @error('data_retorno') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Km inicial</label>
    <input type="number" name="km_inicial" value="{{ old('km_inicial', $viagem->km_inicial ?? '') }}"
           class="form-control @error('km_inicial') is-invalid @enderror">
    @error('km_inicial') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Km final</label>
    <input type="number" name="km_final" value="{{ old('km_final', $viagem->km_final ?? '') }}"
           class="form-control @error('km_final') is-invalid @enderror">
    @error('km_final') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-md-6">
    <label class="form-label">Destino</label>
    <input type="text" name="destino" maxlength="100" value="{{ old('destino', $viagem->destino ?? '') }}"
           class="form-control @error('destino') is-invalid @enderror">
    @error('destino') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12">
    <label class="form-label">Finalidade</label>
    <input type="text" name="finalidade" maxlength="255" value="{{ old('finalidade', $viagem->finalidade ?? '') }}"
           class="form-control @error('finalidade') is-invalid @enderror">
    @error('finalidade') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('viagens.index') }}" class="btn btn-secondary">Cancelar</a>
</div>