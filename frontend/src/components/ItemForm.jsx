import { useState } from 'react';

export default function ItemForm({ onSubmit, editingItem, onCancelEdit }) {
  const [name, setName] = useState(editingItem?.name || '');
  const [description, setDescription] = useState(editingItem?.description || '');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name.trim()) return;
    onSubmit({ name: name.trim(), description: description.trim() });
    setName('');
    setDescription('');
  };

  return (
    <form className="form" onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="Item name"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <input
        type="text"
        placeholder="Description (optional)"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />
      <button type="submit">{editingItem ? 'Update' : 'Add'}</button>
      {editingItem && (
        <button type="button" onClick={onCancelEdit} style={{ background: '#6c757d' }}>
          Cancel
        </button>
      )}
    </form>
  );
}
