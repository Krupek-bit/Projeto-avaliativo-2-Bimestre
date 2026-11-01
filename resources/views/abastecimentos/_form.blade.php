<div class="row g-3">
  <div class="col-12 col-md-6">
    <label class="form-label">Veículo</label>
    <select name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach($veiculos as $v)
        <option value="{{ $v->id_veiculo }}" @selected(old('id_veiculo', $abastecimento->id_veiculo ?? '') == $v->id_veiculo)>
          {{ $v->placa }} - {{ $v->modelo }}
        </option>
      @endforeach
    </select>
    @error('id_veiculo') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Data</label>
    <input type="date" name="data_abastecimento"
           value="{{ old('data_abastecimento', isset($abastecimento) ? \Carbon\Carbon::parse($abastecimento->data_abastecimento)->format('Y-m-d') : '') }}"
           class="form-control @error('data_abastecimento') is-invalid @enderror">
    @error('data_abastecimento') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Combustível</label>
    <select name="tipo_combustivel" class="form-select @error('tipo_combustivel') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach(['Gasolina', 'Etanol', 'Diesel', 'GNV'] as $c)
        <option value="{{ $c }}" @selected(old('tipo_combustivel', $abastecimento->tipo_combustivel ?? '') === $c)>{{ $c }}</option>
      @endforeach
    </select>
    @error('tipo_combustivel') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Litros</label>
    <input type="number" step="0.01" name="litros" value="{{ old('litros', $abastecimento->litros ?? '') }}"
           class="form-control @error('litros') is-invalid @enderror">
    @error('litros') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Valor por litro</label>
    <input type="number" step="0.01" name="valor_litro" value="{{ old('valor_litro', $abastecimento->valor_litro ?? '') }}"
           class="form-control @error('valor_litro') is-invalid @enderror">
    @error('valor_litro') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Valor total</label>
    <input type="number" step="0.01" name="valor_total" value="{{ old('valor_total', $abastecimento->valor_total ?? '') }}"
           class="form-control @error('valor_total') is-invalid @enderror">
    @error('valor_total') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-6 col-md-3">
    <label class="form-label">Quilometragem</label>
    <input type="number" name="quilometragem" value="{{ old('quilometragem', $abastecimento->quilometragem ?? '') }}"
           class="form-control @error('quilometragem') is-invalid @enderror">
    @error('quilometragem') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('abastecimentos.index') }}" class="btn btn-secondary">Cancelar</a>
</div>