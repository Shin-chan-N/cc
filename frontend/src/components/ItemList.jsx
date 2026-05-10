export default function ItemList({ items, onToggle, onEdit, onDelete }) {
  if (items.length === 0) {
    return <p className="loading">No items yet. Add one above!</p>;
  }

  return (
    <ul className="item-list">
      {items.map((item) => (
        <li key={item._id} className="item">
          <input
            type="checkbox"
            checked={item.completed}
            onChange={() => onToggle(item._id, { completed: !item.completed })}
          />
          <span className={item.completed ? 'completed' : ''}>
            {item.name}
            {item.description && <small> - {item.description}</small>}
          </span>
          <button className="edit" onClick={() => onEdit(item)}>
            Edit
          </button>
          <button className="delete" onClick={() => onDelete(item._id)}>
            Delete
          </button>
        </li>
      ))}
    </ul>
  );
}
