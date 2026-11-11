<div class="row g-3">
    <div class="col-12 col-md-6">
        <label class="form-label">Veículo</label>
        <select name="id_veiculo" class="form-select @error('id_veiculo') is-invalid @enderror" required>
            <option value="">Selecione...</option>
            @foreach($veiculos as $v)
                <option value="{{ $v->id_veiculo }}" @selected(old('id_veiculo') == $v->id_veiculo)>
                    {{ $v->placa }} - {{ $v->modelo }}
                </option>
            @endforeach
        </select>
        @error('id_veiculo')
            <div class="invalid-feedback">{{ $message }}</div>
        @enderror
    </div>

    <div class="col-12 col-md-6">
        <label class="form-label">Motorista</label>
        <select name="id_motorista" class="form-select @error('id_motorista') is-invalid @enderror" required>
            <option value="">Selecione...</option>
            @foreach($motoristas as $m)
                <option value="{{ $m->id_motorista }}" @selected(old('id_motorista') == $m->id_motorista)>
                    {{ $m->nome }}
                </option>
            @endforeach
        </select>
        @error('id_motorista')
            <div class="invalid-feedback">{{ $message }}</div>
        @enderror
    </div>

    <div class="col-12 col-md-4">
        <label class="form-label">Quilometragem inicial</label>
        <input type="number" name="km_inicial" min="0"
            value="{{ old('km_inicial') }}"
            class="form-control @error('km_inicial') is-invalid @enderror"
            required>
        @error('km_inicial')
            <div class="invalid-feedback">{{ $message }}</div>
        @enderror
    </div>

    <div class="col-12 col-md-8">
        <label class="form-label">Destino</label>
        <input type="text" name="destino" maxlength="100"
            value="{{ old('destino') }}"
            class="form-control @error('destino') is-invalid @enderror"
            required>
        @error('destino')
            <div class="invalid-feedback">{{ $message }}</div>
        @enderror
    </div>

    <div class="col-12">
        <label class="form-label">Finalidade</label>
        <input type="text" name="finalidade" maxlength="255"
            value="{{ old('finalidade') }}"
            class="form-control @error('finalidade') is-invalid @enderror">
        @error('finalidade')
            <div class="invalid-feedback">{{ $message }}</div>
        @enderror
    </div>

    @error('viagem')
        <div class="col-12">
            <div class="alert alert-danger">{{ $message }}</div>
        </div>
    @enderror
</div>

<div class="mt-4 d-flex gap-2">
    <button type="submit" class="btn btn-success">Iniciar viagem</button>
    <a href="{{ route('viagens.index') }}" class="btn btn-secondary">Cancelar</a>
</div>
