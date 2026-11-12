@extends('layouts.app')

@section('titulo', 'Registrar quilometragem')

@section('content')
<h1 class="h3 mb-3">Registrar quilometragem</h1>

<form method="POST" action="{{ route('hodometros.store') }}">
  @csrf

  <div class="row g-3">
    <div class="col-12 col-md-6">
      <label for="id_veiculo" class="form-label">Veículo</label>
      <select id="id_veiculo" name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror">
        <option value="">Selecione...</option>
        @foreach($veiculos as $veiculo)
          <option value="{{ $veiculo->id_veiculo }}" @selected(old('id_veiculo') == $veiculo->id_veiculo)>
            {{ $veiculo->placa }} - {{ $veiculo->modelo }}
          </option>
        @endforeach
      </select>
      @error('id_veiculo') <div class="invalid-feedback">{{ $message }}</div> @enderror
    </div>

    <div class="col-12 col-sm-6 col-md-3">
      <label for="data_registro" class="form-label">Data</label>
      <input id="data_registro" type="date" name="data_registro" value="{{ old('data_registro', now()->format('Y-m-d')) }}"
             class="form-control @error('data_registro') is-invalid @enderror">
      @error('data_registro') <div class="invalid-feedback">{{ $message }}</div> @enderror
    </div>

    <div class="col-12 col-sm-6 col-md-3">
      <label for="quilometragem" class="form-label">Quilometragem</label>
      <input id="quilometragem" type="number" min="0" name="quilometragem" value="{{ old('quilometragem') }}"
             class="form-control @error('quilometragem') is-invalid @enderror">
      @error('quilometragem') <div class="invalid-feedback">{{ $message }}</div> @enderror
    </div>

    <div class="col-12">
      <label for="observacao" class="form-label">Observação</label>
      <textarea id="observacao" name="observacao" rows="3" maxlength="255"
                class="form-control @error('observacao') is-invalid @enderror">{{ old('observacao') }}</textarea>
      @error('observacao') <div class="invalid-feedback">{{ $message }}</div> @enderror
    </div>
  </div>

  <div class="mt-4 d-grid d-sm-flex gap-2">
    <button class="btn btn-success">Salvar</button>
    <a href="{{ route('hodometros.index') }}" class="btn btn-secondary">Cancelar</a>
  </div>
</form>
@endsection
