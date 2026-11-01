<div class="row g-3">
  <div class="col-md-4">
    <label class="form-label">Placa</label>
    <input type="text" name="placa" maxlength="10" value="{{ old('placa', $veiculo->placa ?? '') }}"
           class="form-control @error('placa') is-invalid @enderror">
    @error('placa') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-4">
    <label class="form-label">Marca</label>
    <input type="text" name="marca" value="{{ old('marca', $veiculo->marca ?? '') }}"
           class="form-control @error('marca') is-invalid @enderror">
    @error('marca') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-4">
    <label class="form-label">Modelo</label>
    <input type="text" name="modelo" value="{{ old('modelo', $veiculo->modelo ?? '') }}"
           class="form-control @error('modelo') is-invalid @enderror">
    @error('modelo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-3">
    <label class="form-label">Ano</label>
    <input type="number" name="ano" value="{{ old('ano', $veiculo->ano ?? '') }}"
           class="form-control @error('ano') is-invalid @enderror">
    @error('ano') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-3">
    <label class="form-label">Tipo</label>
    <input type="text" name="tipo" value="{{ old('tipo', $veiculo->tipo ?? '') }}"
           class="form-control @error('tipo') is-invalid @enderror" placeholder="Carro, caminhão...">
    @error('tipo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-2">
    <label class="form-label">Capacidade</label>
    <input type="number" step="0.01" name="capacidade" value="{{ old('capacidade', $veiculo->capacidade ?? '') }}"
           class="form-control @error('capacidade') is-invalid @enderror">
    @error('capacidade') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-2">
    <label class="form-label">Status</label>
    <select name="status" class="form-select @error('status') is-invalid @enderror">
      @foreach(['ativo', 'em_viagem'] as $s)
        <option value="{{ $s }}" @selected(old('status', $veiculo->status ?? 'ativo') === $s)>{{ ucfirst(str_replace('_', ' ', $s)) }}</option>
      @endforeach
    </select>
    @error('status') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-md-2">
    <label class="form-label">Km atual</label>
    <input type="number" name="quilometragem_atual" value="{{ old('quilometragem_atual', $veiculo->quilometragem_atual ?? 0) }}"
           class="form-control @error('quilometragem_atual') is-invalid @enderror">
    @error('quilometragem_atual') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('veiculos.index') }}" class="btn btn-secondary">Cancelar</a>
</div>