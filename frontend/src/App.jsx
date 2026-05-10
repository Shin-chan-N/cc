import { useState, useEffect } from 'react';
import ItemForm from './components/ItemForm';
import ItemList from './components/ItemList';
import { getItems, createItem, updateItem, deleteItem } from './api/items';

export default function App() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingItem, setEditingItem] = useState(null);

  useEffect(() => {
    getItems()
      .then((res) => setItems(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const handleCreateOrUpdate = async (data) => {
    try {
      if (editingItem) {
        const res = await updateItem(editingItem._id, data);
        setItems((prev) => prev.map((i) => (i._id === editingItem._id ? res.data : i)));
        setEditingItem(null);
      } else {
        const res = await createItem(data);
        setItems((prev) => [res.data, ...prev]);
      }
    } catch (error) {
      console.error(error);
    }
  };

  const handleToggle = async (id, data) => {
    try {
      const res = await updateItem(id, data);
      setItems((prev) => prev.map((i) => (i._id === id ? res.data : i)));
    } catch (error) {
      console.error(error);
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteItem(id);
      setItems((prev) => prev.filter((i) => i._id !== id));
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="container">
      <h1>MERN Stack App</h1>
      <ItemForm
        onSubmit={handleCreateOrUpdate}
        editingItem={editingItem}
        onCancelEdit={() => setEditingItem(null)}
      />
      {loading ? (
        <p className="loading">Loading...</p>
      ) : (
        <ItemList
          items={items}
          onToggle={handleToggle}
          onEdit={setEditingItem}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
}
