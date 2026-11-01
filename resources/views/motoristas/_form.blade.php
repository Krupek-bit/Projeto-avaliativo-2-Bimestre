<div class="row g-3">
  <div class="col-12 col-md-6">
    <label class="form-label">Nome</label>
    <input type="text" name="nome" maxlength="100" value="{{ old('nome', $motorista->nome ?? '') }}"
           class="form-control @error('nome') is-invalid @enderror">
    @error('nome') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">CNH</label>
    <input type="text" name="cnh" maxlength="20" value="{{ old('cnh', $motorista->cnh ?? '') }}"
           class="form-control @error('cnh') is-invalid @enderror">
    @error('cnh') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Categoria da CNH</label>
    <select name="categoria_cnh" class="form-select @error('categoria_cnh') is-invalid @enderror">
      <option value="">Selecione...</option>
      @foreach(['A', 'B', 'C', 'D', 'E', 'AB', 'AC', 'AD', 'AE'] as $c)
        <option value="{{ $c }}" @selected(old('categoria_cnh', $motorista->categoria_cnh ?? '') === $c)>{{ $c }}</option>
      @endforeach
    </select>
    @error('categoria_cnh') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Telefone</label>
    <input type="text" name="telefone" maxlength="20" value="{{ old('telefone', $motorista->telefone ?? '') }}"
           class="form-control @error('telefone') is-invalid @enderror">
    @error('telefone') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Data de admissão</label>
    <input type="date" name="data_admissao"
           value="{{ old('data_admissao', isset($motorista) ? \Carbon\Carbon::parse($motorista->data_admissao)->format('Y-m-d') : '') }}"
           class="form-control @error('data_admissao') is-invalid @enderror">
    @error('data_admissao') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Validade da CNH</label>
    <input type="date" name="validade_cnh"
           value="{{ old('validade_cnh', isset($motorista) ? \Carbon\Carbon::parse($motorista->validade_cnh)->format('Y-m-d') : '') }}"
           class="form-control @error('validade_cnh') is-invalid @enderror">
    @error('validade_cnh') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
  <div class="col-12 col-sm-6 col-md-3">
    <label class="form-label">Status</label>
    <select name="status" class="form-select @error('status') is-invalid @enderror">
      @foreach(['ativo'] as $s)
        <option value="{{ $s }}" @selected(old('status', $motorista->status ?? 'ativo') === $s)>{{ ucfirst($s) }}</option>
      @endforeach
    </select>
    @error('status') <div class="invalid-feedback">{{ $message }}</div> @enderror
  </div>
</div>

<div class="mt-4 d-grid d-sm-flex gap-2">
  <button class="btn btn-success">Salvar</button>
  <a href="{{ route('motoristas.index') }}" class="btn btn-secondary">Cancelar</a>
</div>